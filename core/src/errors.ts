export class OraklError extends Error {
  constructor(public readonly code: OraklErrorCode, message?: string, public readonly value?) {
    super(message)
    this.name = OraklErrorCode[code]
    this.value = value
    Object.setPrototypeOf(this, new.target.prototype)
  }
}

export enum OraklErrorCode {
  NonExistentEventError = 10000,
  AggregatorJobCanTakeMoreBreak,
  AggregatorNotFound,
  FailedToGetAggregate,
  FailedToGetAggregator,
  GetListenerRequestFailed,
  GetVrfConfigRequestFailed,
  IncompleteDataFeed,
  IndexOutOfBoundaries,
  InvalidAdapter,
  InvalidAggregator,
  InvalidDataFeed,
  InvalidDataFeedFormat,
  InvalidDecodedMesssageLength,
  InvalidListenerConfig,
  InvalidOperator,
  InvalidReducer,
  MissingAdapter,
  MissingAggregator,
  MissingJsonRpcProvider,
  MissingKeyInJson,
  MissingKeyValuePair,
  MissingMnemonic,
  NoListenerFoundGivenRequirements,
  ProviderNetworkError,
  TxCannotEstimateGasError,
  TxInvalidAddress,
  TxNotMined,
  TxProcessingResponseError,
  UndefinedAggregator,
  UndefinedListenerRequested,
  UnexpectedNumberOfJobsInQueue,
  UnexpectedQueryOutput,
  UniformWrongParams
}
