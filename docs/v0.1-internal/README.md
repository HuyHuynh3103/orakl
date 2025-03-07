# v0.1 for internal

## Accounts

| id | key type | key value                                                          | use         |
|----|----------|--------------------------------------------------------------------|-------------|
| 0  | public   | 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266                         | deployer    |
| 0  | private  | 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 |             |
| 1  | public   | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8                         | consumer    |
| 1  | private  | 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d |             |
| 2  | public   | 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC                         | feedOracle0 |
| 2  | private  | 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a |             |
| 3  | public   | 0x90F79bf6EB2c4f870365E785982E1f101E93b906                         | feedOracle1 |
| 3  | private  | 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6 |             |
| 4  | public   | 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65                         | feedOracle2 |
| 4  | private  | 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a |             |
| 5  | public   | 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc                         |             |
| 5  | private  | 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba |             |
| 6  | public   | 0x976EA74026E726554dB657fA54763abd0C3a0aa9                         |             |
| 6  | private  | 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e |             |
| 7  | public   | 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955                         |             |
| 7  | private  | 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356 |             |
| 8  | public   | 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f                         |             |
| 8  | private  | 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97 |             |
| 9  | public   | 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720                         |             |
| 9  | private  | 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 |             |
| 10 | public   | 0xBcd4042DE499D14e55001CcbB24a551F3b954096                         |             |
| 10 | private  | 0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897 |             |
| 11 | public   | 0x71bE63f3384f5fb98995898A86B02Fb2426c5788                         |             |
| 11 | private  | 0x701b615bbdfb9de65240bc28bd21bbc0d996645a3dd57e7b12bc2bdf6f192c82 |             |
| 12 | public   | 0xFABB0ac9d68B0B445fB7357272Ff202C5651694a                         |             |
| 12 | private  | 0xa267530f49f8280200edf313ee7af6b827f2a8bce2897751d06a843f644967b1 |             |
| 13 | public   | 0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec                         |             |
| 13 | private  | 0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd |             |
| 14 | public   | 0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097                         |             |
| 14 | private  | 0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa |             |
| 15 | public   | 0xcd3B766CCDd6AE721141F452C550Ca635964ce71                         |             |
| 15 | private  | 0x8166f546bab6da521a8369cab06c5d2b9e46670292d85c875ee9ec20e84ffb61 |             |
| 16 | public   | 0x2546BcD3c84621e976D8185a91A922aE77ECEc30                         |             |
| 16 | private  | 0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0 |             |
| 17 | public   | 0xbDA5747bFD65F08deb54cb465eB87D40e51B197E                         |             |
| 17 | private  | 0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd |             |
| 18 | public   | 0xdD2FD4581271e230360230F9337D5c0430Bf44C0                         |             |
| 18 | private  | 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0 |             |
| 19 | public   | 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199                         |             |
| 19 | private  | 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e |             |

## Payment methods

Currently, we support two payment methods:

* `Prepayment` (`contracts/src/v0.1/Prepayment.sol`)
* Direct method

### `Prepayment`
`Prepayment` smart contract allows anybody (later referred as account owner) to create an account (`createAccount()`) that can be used to pay for Orakl services (VRF, Request-Response, ...).

Before `Prepayment` can be used with specific service, it has to be connected with coordinator of that service (`addCoordinator(address coordinator)`).
Later, we can remove coordinator from prepayment (`removeCoordinator(address coordinator)`).
Connection and removal of coordinator from `Prepayment` has to be executed by account with `DEFAULT_ADMIN_ROLE`.

KLAY tokens can be deposited (`deposit(uint64 accId)`) by anyone with knowledge of account ID (`uint64 accId`).
Account owner can withdraw (`withdraw(uint64 accId, uint96 amount)`) any amount of  KLAY tokens from its own account (`uint64 accId`).
In order to proceed with withdrawal, there must be no ongoing unfulfilled request (`pendingRequestExists(uint64 accId)`) through the account of interest.
Account can be permanently removed (`cancelAccount(uint64 accId, address to)`) and remaining KLAY tokens are returned to predefined address (`address to`).

Before an account can be used by any service connected to `Prepayment`, account owner has to attach consumer (`addConsumer(uint64 accId, address consumer)`) to account.
Later, account owner can remove consumer (`removeConsumer(uint64 accId, address consumer)`) when consumer is not used in any of provided services.

To change the owner of account, account owner can request (`function requestAccountOwnerTransfer(uint64 accId, address newOwner)`) to transfer the ownership.
Acount ownership is not changed until proposed owner accepts the account ownership (`acceptAccountOwnerTransfer(uint64 accId)`).

#### How to deploy and setup `Prepayment`

Constructor of `Prepayment` smart contract does not require any parameters.
The signer that sends the deployment transaction will receive [`DEFAULT_ADMIN_ROLE` role](https://docs.openzeppelin.com/contracts/4.x/access-control#using-access-control).

After the deployment, one has to connect it with coordinator contract that implements `CoordinatorBaseInterface` interface (`contracts/src/v0.1/interfaces/CoordinatorBaseInterface.sol`).
It can be accomplished by calling `addCoordinator(address coordinator)` function.

The order of operation has to be as follows:

1. Deploy `Prepayment`
2. Deploy `Coordinator`
3. Connect `Coordinator` with `Prepayment` (`prepayment.addCoordinator(coordinator)`)

#### Roles


`Prepayment` contract is utilizing OpenZeppelin's [`AccessControlEnumeratble` and `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable).

* `DEFAULT_ADMIN_ROLE`
* `WITHDRAWER_ROLE`
* `COORDINATOR_ROLE`

## Aggregator & Aggregator Proxy

On-chain part of Aggregator is implemented in

* `Aggregator` ([`contracts/src/v0.1/Aggregator.sol`](`../../contracts/src/v0.1/Aggregator.sol`))
* `AggregatorProxy` ([`contracts/src/v0.1/AggregatorProxy.sol`](`../../contracts/src/v0.1/AggregatorProxy.sol`))

### How to deploy and setup `Aggregator`

`Aggregator` smart contract is used for collecting data from off-chain submitted by off-chain oracles.
`AggregatorProxy` is a smart contract that enables consumers to read the latest and as well as historical data aggregated in `Aggregator`.

* `paymentAmount`
* `timeout` (Currently not supported!)
* `validator` (Not tested yet. Passing `null` address.)
* `minSubmissionValue` (Minimum allowed submission by off-chain oracle)
* `maxSubmissionValue` (Maximum allowed submission by off-chain oracle)
* `decimals` (Number of decimals to offset the answer by. The same number is also defined in adapter definition that is related to aggregator)
* `description` (Could include the adapter hash?)

After, the `Aggregator` is deployed, we have to define which off-chain oracles can report their off-chain values there.
You can learn more about it in the section below.

### How to defined oracles that will submit data from off-chain?

`Aggregator` defines a function `changeOracles` which allows an update of oracles that can report their off-chain values.
This function has to be called additionally after deployment to allow feed updates.

`changeOracles` defines which oracles should be removed (`address[] calldata _removed`), which oracles should be added (`address[] calldata _added`) and who is allowed to withdraw (`withdrawPayment`) oracle's rewards (`address[] calldata _addedAdmins`).

Every aggregator has lower (`uint32 _minSubmissionCount`) and upper (`uint32 _maxSubmissionCount`) boundary on how many submissions are required to compute a new answer for a round.

## Request-Response

`RequestResponseCoordinator` (`contracts/src/v0.1/RequestResponseCoordinator.sol`) contract handles all the **Request-Response** requests.

* HTTP GET Single Word Response
* HTTP GET Multi-Variable Word Responses
* HTTP GET Element in Array Response
* HTTP GET Large Responses

## Verifiable Random Function

On-chain part of Verifiable Random Function is implemented in following contracts:

* `VRFCoordinator` (`contracts/src/v0.1/VRFCoordinator.sol`)
* `VRFConsumerBase` (`contracts/src/v0.1/VRFConsumerBase.sol`)

`VRFCoordinator` accept requests for random words from consumers and subsequently it is used to respond with generated VRF proof from off-chain oracle.

Every request includes `bytes32 keyhash` which uniquely identify an off-chain oracle that is requested for fulfilling randomness request.

#### Limitations of `VRFCoordinator`

* `MAX_REQUEST_CONFIRMATIONS` (Currently not supported!)
* `MAX_NUM_WORDS = 500`
* `GAS_FOR_CALL_EXACT_CHECK = 5,000`

#### How to deploy and setup `VRFcoordinator`

Before being able to deploy `VRFCoordinator` one must have already deployed contract implementing `PrepaymentInterface` (`contracts/src/v0.1/interfaces/PrepaymentInterface.sol`). Address of contract that implements `PrepaymentInterface` is passed as single parameter to `VRFCoordinator` constructor.

```
constructor(PrepaymentInterface prepayment)
```

`VRFCoordinator` has to be then connected to `Prepayment` or any other smart contract that implements (`PrepaymentInterface`) interface.

Configuration of `VRFCoordinator` is performed through `setConfig` function.
`setConfig` allows to update following parameters:

* `maxGasLimit` (Total allowed gas limit for processing response)
* `gasAfterPaymentCalculation` (Global gas limit for operations after `calculatePaymentAmount` inside of `fulfillRandomWords`. Operations could be repriced, therefore this value is configurable.)
* `feeConfig` (Fee structure with 5 different price tiers and request count boundaries)

#### Adding oracle to VRFCoordinator

In order to add new VRF off-chain oracle, one must generate VRF keys first.
VRF keys can be generated using `yarn keygen` command.
Then, call `registerProvingKey(address oracle, uint256[2] calldata publicProvingKey)` to assign oracle and its proving keys to `VRFCoordinator`.
The registration can be performed only by owner of `VRFCordinator`.
After successful transaction, consumers can request random words through oracle newly added to `VRFCoordinator`.

Public proving key (key) and oracle's address (value) will be stored in mapping `s_provingKeys`.
Public proving key will be additionally stored in `s_provingKeyHashes` array.

#### Removing oracle from VRF coordinator

Registered VRF oracle can be removed anytime through `deregisterProvingKey(uint256[2] calldata publicProvingKey)` function.
The deregistration can be performed only by owner of `VRFCordinator`.
After successful transaction, consumers will not be able to request random words from removed oracle through `VRFCoordinator`.


#### Roles

* `ConfifmedOwner` from Chainlink

## Events

There are important events we need to collect and analyze to provide good user experience.

## Data Feed

* `NewRound`

## Request-Response

The following events are defined within `contracts/src/v0.1/RequestResponseCoordinator.sol`.

* `Requested`
* `Cancelled`
* `Fulfilled`

### Verifiable Random Function

The following events are defined within `contracts/src/v0.1/VRFCoordinator.sol`.

* `RandomWordsRequested`
* `RandomWordsFulfilled`
