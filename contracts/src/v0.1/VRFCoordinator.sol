// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFCoordinatorV2.sol

import "./interfaces/CoordinatorBaseInterface.sol";
import "./interfaces/PrepaymentInterface.sol";
import "./interfaces/TypeAndVersionInterface.sol";
import "./interfaces/VRFCoordinatorInterface.sol";
import "./libraries/VRF.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VRFConsumerBase.sol";

contract VRFCoordinator is
    CoordinatorBaseInterface,
    Ownable,
    TypeAndVersionInterface,
    VRFCoordinatorInterface
{
    uint32 public constant MAX_NUM_WORDS = 500;
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
    // and some arithmetic operations.
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

    bytes32[] private s_provingKeyHashes;

    /* keyHash */
    /* oracle */
    mapping(bytes32 => address) private s_provingKeys;

    /* requestID */
    /* commitment */
    mapping(uint256 => bytes32) private s_requestCommitments;

    uint256 public s_minBalance;

    // RequestCommitment holds information sent from off-chain oracle
    // describing details of request.
    struct RequestCommitment {
        uint64 blockNum;
        uint64 accId;
        uint32 callbackGasLimit;
        uint32 numWords;
        address sender;
    }

    struct Config {
        uint32 maxGasLimit;
        // Reentrancy protection.
        bool reentrancyLock;
        // Gas to cover oracle payment after we calculate the payment.
        // We make it configurable in case those operations are repriced.
        uint32 gasAfterPaymentCalculation;
    }
    Config private s_config;

    struct FeeConfig {
        // Flat fee charged per fulfillment in millionths of KLAY
        // So fee range is [0, 2^32/10^6].
        uint32 fulfillmentFlatFeeKlayPPMTier1;
        uint32 fulfillmentFlatFeeKlayPPMTier2;
        uint32 fulfillmentFlatFeeKlayPPMTier3;
        uint32 fulfillmentFlatFeeKlayPPMTier4;
        uint32 fulfillmentFlatFeeKlayPPMTier5;
        uint24 reqsForTier2;
        uint24 reqsForTier3;
        uint24 reqsForTier4;
        uint24 reqsForTier5;
    }
    FeeConfig private s_feeConfig;

    PrepaymentInterface s_prepayment;

    struct DirectPaymentConfig {
        uint256 fulfillmentFee;
        uint256 baseFee;
    }

    DirectPaymentConfig s_directPaymentConfig;

    error InvalidKeyHash(bytes32 keyHash);
    error InvalidConsumer(uint64 accId, address consumer);
    error InvalidAccount();
    error GasLimitTooBig(uint32 have, uint32 want);
    error NumWordsTooBig(uint32 have, uint32 want);
    error ProvingKeyAlreadyRegistered(bytes32 keyHash);
    error NoSuchProvingKey(bytes32 keyHash);
    error NoCorrespondingRequest();
    error IncorrectCommitment();
    error Reentrant();
    error InsufficientPayment(uint256 have, uint256 want);
    error RefundFailure();

    event ProvingKeyRegistered(bytes32 keyHash, address indexed oracle);
    event ProvingKeyDeregistered(bytes32 keyHash, address indexed oracle);
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed accId,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender,
        bool isDirectPayment
    );
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint256 payment,
        bool success
    );
    event ConfigSet(uint32 maxGasLimit, uint32 gasAfterPaymentCalculation, FeeConfig feeConfig);
    event DirectPaymentConfigSet(uint256 fulfillmentFee, uint256 baseFee);
    event MinBalanceSet(uint256 minBalance);
    event PrepaymentSet(address prepayment);

    modifier nonReentrant() {
        if (s_config.reentrancyLock) {
            revert Reentrant();
        }
        _;
    }

    modifier onlyValidKeyHash(bytes32 keyHash) {
        if (s_provingKeys[keyHash] == address(0)) {
            revert InvalidKeyHash(keyHash);
        }
        _;
    }

    constructor(address prepayment) {
        s_prepayment = PrepaymentInterface(prepayment);
        emit PrepaymentSet(prepayment);
    }

    /**
     * @notice Registers a proving key to an oracle.
     * @param oracle address of the oracle
     * @param publicProvingKey key that oracle can use to submit VRF fulfillments
     */
    function registerProvingKey(
        address oracle,
        uint256[2] calldata publicProvingKey
    ) external onlyOwner {
        bytes32 kh = hashOfKey(publicProvingKey);
        if (s_provingKeys[kh] != address(0)) {
            revert ProvingKeyAlreadyRegistered(kh);
        }
        s_provingKeys[kh] = oracle;
        s_provingKeyHashes.push(kh);
        emit ProvingKeyRegistered(kh, oracle);
    }

    /**
     * @notice Deregisters a proving key to an oracle.
     * @param publicProvingKey key that oracle can use to submit VRF fulfillments
     */
    function deregisterProvingKey(uint256[2] calldata publicProvingKey) external onlyOwner {
        bytes32 kh = hashOfKey(publicProvingKey);
        address oracle = s_provingKeys[kh];
        if (oracle == address(0)) {
            revert NoSuchProvingKey(kh);
        }
        delete s_provingKeys[kh];
        for (uint256 i = 0; i < s_provingKeyHashes.length; i++) {
            if (s_provingKeyHashes[i] == kh) {
                bytes32 last = s_provingKeyHashes[s_provingKeyHashes.length - 1];
                // Copy last element and overwrite kh to be deleted with it
                s_provingKeyHashes[i] = last;
                s_provingKeyHashes.pop();
                break;
            }
        }
        emit ProvingKeyDeregistered(kh, oracle);
    }

    /**
     * @notice Sets the configuration of the VRF coordinator
     * @param maxGasLimit global max for request gas limit
     * @param gasAfterPaymentCalculation gas used in doing accounting after completing the gas measurement
     * @param feeConfig fee tier configuration
     */
    function setConfig(
        uint32 maxGasLimit,
        uint32 gasAfterPaymentCalculation,
        FeeConfig memory feeConfig
    ) external onlyOwner {
        s_config = Config({
            maxGasLimit: maxGasLimit,
            gasAfterPaymentCalculation: gasAfterPaymentCalculation,
            reentrancyLock: false
        });
        s_feeConfig = feeConfig;
        emit ConfigSet(maxGasLimit, gasAfterPaymentCalculation, s_feeConfig);
    }

    function getConfig()
        external
        view
        returns (uint32 maxGasLimit, uint32 gasAfterPaymentCalculation)
    {
        return (s_config.maxGasLimit, s_config.gasAfterPaymentCalculation);
    }

    function getFeeConfig()
        external
        view
        returns (
            uint32 fulfillmentFlatFeeKlayPPMTier1,
            uint32 fulfillmentFlatFeeKlayPPMTier2,
            uint32 fulfillmentFlatFeeKlayPPMTier3,
            uint32 fulfillmentFlatFeeKlayPPMTier4,
            uint32 fulfillmentFlatFeeKlayPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5
        )
    {
        return (
            s_feeConfig.fulfillmentFlatFeeKlayPPMTier1,
            s_feeConfig.fulfillmentFlatFeeKlayPPMTier2,
            s_feeConfig.fulfillmentFlatFeeKlayPPMTier3,
            s_feeConfig.fulfillmentFlatFeeKlayPPMTier4,
            s_feeConfig.fulfillmentFlatFeeKlayPPMTier5,
            s_feeConfig.reqsForTier2,
            s_feeConfig.reqsForTier3,
            s_feeConfig.reqsForTier4,
            s_feeConfig.reqsForTier5
        );
    }

    /**
     * @inheritdoc VRFCoordinatorInterface
     */
    function getRequestConfig() external view returns (uint32, bytes32[] memory) {
        return (s_config.maxGasLimit, s_provingKeyHashes);
    }

    function setDirectPaymentConfig(
        DirectPaymentConfig memory directPaymentConfig
    ) public onlyOwner {
        s_directPaymentConfig = directPaymentConfig;
        emit DirectPaymentConfigSet(
            directPaymentConfig.fulfillmentFee,
            directPaymentConfig.baseFee
        );
    }

    function getDirectPaymentConfig() external view returns (uint256, uint256) {
        return (s_directPaymentConfig.fulfillmentFee, s_directPaymentConfig.baseFee);
    }

    function estimateDirectPaymentFee() public view returns (uint256) {
        return s_directPaymentConfig.fulfillmentFee + s_directPaymentConfig.baseFee;
    }

    function getPrepaymentAddress() public view returns (address) {
        return address(s_prepayment);
    }

    /**
     * @notice Get request commitment
     * @param requestId id of request
     * @dev used to determine if a request is fulfilled or not
     */
    function getCommitment(uint256 requestId) external view returns (bytes32) {
        return s_requestCommitments[requestId];
    }

    function setMinBalance(uint256 minBalance) public onlyOwner {
        s_minBalance = minBalance;
        emit MinBalanceSet(minBalance);
    }

    /*
     * @notice Fulfill a randomness request
     * @param proof contains the proof and randomness
     * @param rc request commitment pre-image, committed to at request time
     * @return payment amount billed to the account
     * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
     */
    function fulfillRandomWords(
        VRF.Proof memory proof,
        RequestCommitment memory rc,
        bool isDirectPayment
    ) external nonReentrant returns (uint256) {
        uint256 startGas = gasleft();
        (bytes32 keyHash, uint256 requestId, uint256 randomness) = getRandomnessFromProof(
            proof,
            rc
        );

        uint256[] memory randomWords = new uint256[](rc.numWords);
        for (uint256 i = 0; i < rc.numWords; i++) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        delete s_requestCommitments[requestId];
        VRFConsumerBase v;
        bytes memory resp = abi.encodeWithSelector(
            v.rawFulfillRandomWords.selector,
            requestId,
            randomWords
        );

        // Call with explicitly the amount of callback gas requested
        // Important to not let them exhaust the gas budget and avoid oracle payment.
        // Do not allow any non-view/non-pure coordinator functions to be called
        // during the consumers callback code via reentrancyLock.
        // Note that callWithExactGas will revert if we do not have sufficient gas
        // to give the callee their requested amount.
        s_config.reentrancyLock = true;
        bool success = callWithExactGas(rc.callbackGasLimit, rc.sender, resp);
        s_config.reentrancyLock = false;

        // We want to charge users exactly for how much gas they use in their callback.
        // The gasAfterPaymentCalculation is meant to cover these additional operations where we
        // decrement the account balance and increment the oracles withdrawable balance.
        // We also add the flat KLAY fee to the payment amount.
        // Its specified in millionths of KLAY, if s_config.fulfillmentFlatFeeKlayPPM = 1
        // 1 KLAY / 1e6 = 1e18 pebs / 1e6 = 1e12 pebs.
        (uint256 balance, uint64 reqCount, , ) = s_prepayment.getAccount(rc.accId);

        uint256 payment;
        if (isDirectPayment) {
            payment = balance;
        } else {
            payment = calculatePaymentAmount(
                startGas,
                s_config.gasAfterPaymentCalculation,
                getFeeTier(reqCount)
            );
        }

        s_prepayment.chargeFee(rc.accId, payment, s_provingKeys[keyHash]);

        // FIXME
        //s_withdrawableTokens[s_provingKeys[rc.keyHash]] += payment;

        // Include payment in the event for tracking costs.
        emit RandomWordsFulfilled(requestId, randomness, payment, success);
        return payment;
    }

    /**
     * @notice The type and version of this contract
     * @return Type and version string
     */
    function typeAndVersion() external pure virtual override returns (string memory) {
        return "VRFCoordinator v0.1";
    }

    /*
     * @notice Compute fee based on the request count
     * @param reqCount number of requests
     * @return feePPM fee in KLAY PPM
     */
    function getFeeTier(uint64 reqCount) public view returns (uint32) {
        FeeConfig memory fc = s_feeConfig;
        if (0 <= reqCount && reqCount <= fc.reqsForTier2) {
            return fc.fulfillmentFlatFeeKlayPPMTier1;
        }
        if (fc.reqsForTier2 < reqCount && reqCount <= fc.reqsForTier3) {
            return fc.fulfillmentFlatFeeKlayPPMTier2;
        }
        if (fc.reqsForTier3 < reqCount && reqCount <= fc.reqsForTier4) {
            return fc.fulfillmentFlatFeeKlayPPMTier3;
        }
        if (fc.reqsForTier4 < reqCount && reqCount <= fc.reqsForTier5) {
            return fc.fulfillmentFlatFeeKlayPPMTier4;
        }
        return fc.fulfillmentFlatFeeKlayPPMTier5;
    }

    /**
     * @inheritdoc CoordinatorBaseInterface
     */
    function pendingRequestExists(
        address consumer,
        uint64 accId,
        uint64 nonce
    ) public view returns (bool) {
        for (uint256 i = 0; i < s_provingKeyHashes.length; i++) {
            (uint256 reqId, ) = computeRequestId(s_provingKeyHashes[i], consumer, accId, nonce);
            if (s_requestCommitments[reqId] != 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Returns the proving key hash key associated with this public key
     * @param publicKey the key to return the hash of
     */
    function hashOfKey(uint256[2] memory publicKey) public pure returns (bytes32) {
        return keccak256(abi.encode(publicKey));
    }

    function requestRandomWordsInternal(
        bytes32 keyHash,
        uint64 accId,
        uint32 callbackGasLimit,
        uint32 numWords,
        bool isDirectPayment
    ) internal returns (uint256) {
        // Input validation using the account storage.
        // call to prepayment contract
        address owner = s_prepayment.getAccountOwner(accId);
        if (owner == address(0)) {
            revert InvalidAccount();
        }

        // Its important to ensure that the consumer is in fact who they say they
        // are, otherwise they could use someone else's account balance.
        // A nonce of 0 indicates consumer is not allocated to the acc.
        uint64 currentNonce = s_prepayment.getNonce(msg.sender, accId);
        if (currentNonce == 0) {
            revert InvalidConsumer(accId, msg.sender);
        }

        // No lower bound on the requested gas limit. A user could request 0
        // and they would simply be billed for the proof verification and wouldn't be
        // able to do anything with the random value.
        if (callbackGasLimit > s_config.maxGasLimit) {
            revert GasLimitTooBig(callbackGasLimit, s_config.maxGasLimit);
        }

        if (numWords > MAX_NUM_WORDS) {
            revert NumWordsTooBig(numWords, MAX_NUM_WORDS);
        }

        uint64 nonce = s_prepayment.increaseNonce(msg.sender, accId);
        (uint256 requestId, uint256 preSeed) = computeRequestId(keyHash, msg.sender, accId, nonce);

        s_requestCommitments[requestId] = keccak256(
            abi.encode(requestId, block.number, accId, callbackGasLimit, numWords, msg.sender)
        );
        emit RandomWordsRequested(
            keyHash,
            requestId,
            preSeed,
            accId,
            callbackGasLimit,
            numWords,
            msg.sender,
            isDirectPayment
        );

        return requestId;
    }

    /**
     * @inheritdoc VRFCoordinatorInterface
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 accId,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external nonReentrant onlyValidKeyHash(keyHash) returns (uint256 requestId) {
        (uint256 balance, , , ) = s_prepayment.getAccount(accId);

        if (balance < s_minBalance) {
            revert InsufficientPayment(balance, s_minBalance);
        }
        bool isDirectPayment = false;

        requestId = requestRandomWordsInternal(
            keyHash,
            accId,
            callbackGasLimit,
            numWords,
            isDirectPayment
        );
    }

    /**
     * @inheritdoc VRFCoordinatorInterface
     */
    function requestRandomWordsPayment(
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external payable nonReentrant onlyValidKeyHash(keyHash) returns (uint256) {
        uint256 vrfFee = estimateDirectPaymentFee();
        if (msg.value < vrfFee) {
            revert InsufficientPayment(msg.value, vrfFee);
        }

        uint64 accId = s_prepayment.createAccount();
        s_prepayment.addConsumer(accId, msg.sender);
        bool isDirectPayment = true;
        uint256 requestId = requestRandomWordsInternal(
            keyHash,
            accId,
            callbackGasLimit,
            numWords,
            isDirectPayment
        );
        s_prepayment.deposit{value: vrfFee}(accId);

        uint256 remaining = msg.value - vrfFee;
        if (remaining > 0) {
            (bool sent, ) = msg.sender.call{value: remaining}("");
            if (!sent) {
                revert RefundFailure();
            }
        }

        return requestId;
    }

    function calculatePaymentAmount(
        uint256 startGas,
        uint256 gasAfterPaymentCalculation,
        uint32 fulfillmentFlatFeeKlayPPM
    ) internal view returns (uint256) {
        uint256 paymentNoFee = tx.gasprice * (gasAfterPaymentCalculation + startGas - gasleft());
        uint256 fee = 1e12 * uint256(fulfillmentFlatFeeKlayPPM);
        return paymentNoFee + fee;
    }

    function computeRequestId(
        bytes32 keyHash,
        address sender,
        uint64 accId,
        uint64 nonce
    ) private pure returns (uint256, uint256) {
        uint256 preSeed = uint256(keccak256(abi.encode(keyHash, sender, accId, nonce)));
        return (uint256(keccak256(abi.encode(keyHash, preSeed))), preSeed);
    }

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) private returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
            // We want to ensure that we revert if gasAmount >  63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
            // to revert if gasAmount >  63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                revert(0, 0)
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gasAmount, revert
            // (we subtract g//64 because of EIP-150)
            if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
                revert(0, 0)
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }
            // call and return whether we succeeded. ignore return data
            // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
            success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
        }
        return success;
    }

    function getRandomnessFromProof(
        VRF.Proof memory proof,
        RequestCommitment memory rc
    ) private view returns (bytes32 keyHash, uint256 requestId, uint256 randomness) {
        keyHash = hashOfKey(proof.pk);
        // Only registered proving keys are permitted.
        address oracle = s_provingKeys[keyHash];
        if (oracle == address(0)) {
            revert NoSuchProvingKey(keyHash);
        }
        requestId = uint256(keccak256(abi.encode(keyHash, proof.seed)));
        bytes32 commitment = s_requestCommitments[requestId];
        if (commitment == 0) {
            revert NoCorrespondingRequest();
        }
        if (
            commitment !=
            keccak256(
                abi.encode(
                    requestId,
                    rc.blockNum,
                    rc.accId,
                    rc.callbackGasLimit,
                    rc.numWords,
                    rc.sender
                )
            )
        ) {
            revert IncorrectCommitment();
        }

        bytes32 blockHash = blockhash(rc.blockNum);

        // The seed actually used by the VRF machinery, mixing in the blockhash
        bytes memory actualSeed = abi.encodePacked(
            keccak256(abi.encodePacked(proof.seed, blockHash))
        );
        randomness = VRF.randomValueFromVRFProof(proof, actualSeed); // Reverts on failure
    }
}
