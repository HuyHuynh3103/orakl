import axios from 'axios'
import { URL } from 'node:url'
import { Logger } from 'pino'
import { IAggregator, IAggregate } from '../types'
import { OraklError, OraklErrorCode } from '../errors'
import { ORAKL_NETWORK_API_URL } from '../settings'
import { buildUrl } from '../utils'

export const AGGREGATE_ENDPOINT = buildUrl(ORAKL_NETWORK_API_URL, 'api/v1/aggregate')
export const AGGREGATOR_ENDPOINT = buildUrl(ORAKL_NETWORK_API_URL, 'api/v1/aggregator')

/**
 * Fetch aggregate data from `Orakl Network API` data feed endpoint
 * given aggregator ID.
 *
 * @param {string} aggregator hash
 * @param {Logger} logger
 * @return {number} the latest aggregated value
 * @exception {FailedToGetAggregate}
 */
export async function fetchDataFeed({
  aggregatorHash,
  logger
}: {
  aggregatorHash: string
  logger: Logger
}): Promise<IAggregate> {
  try {
    const url = buildUrl(AGGREGATE_ENDPOINT, `${aggregatorHash}/latest`)
    const response = (await axios.get(url))?.data
    return response
  } catch (e) {
    logger.error(e)
    throw new OraklError(OraklErrorCode.FailedToGetAggregate)
  }
}

/**
 * Get single `Aggregator` given aggregator address.
 *
 * @param {string} aggregator address
 * @param {Logger} logger
 * @return {Aggregator}
 * @exception {FailedToGetAggregator}
 */
export async function getAggregatorGivenAddress({
  aggregatorAddress,
  logger
}: {
  aggregatorAddress: string
  logger: Logger
}): Promise<IAggregator> {
  const url = new URL(AGGREGATOR_ENDPOINT)
  url.searchParams.append('address', aggregatorAddress)

  let response = []
  try {
    response = (await axios.get(url.toString()))?.data
  } catch (e) {
    logger.error(e)
    throw new OraklError(OraklErrorCode.FailedToGetAggregator)
  }

  if (response.length == 1) {
    logger.debug(response)
    return response[0]
  } else if (response.length == 0) {
    const msg = 'No aggregator found'
    logger.error(msg)
    throw new OraklError(OraklErrorCode.FailedToGetAggregator, msg)
  } else {
    const msg = `Expected one aggregator, received ${response.length}`
    logger.error(msg)
    throw new OraklError(OraklErrorCode.FailedToGetAggregator, msg)
  }
}

/**
 * Get all active `Aggregator`s from `Orakl API` given an aggregator
 * hash and chain.
 *
 * @param {string} chain name
 * @param {Logger} logger
 * @return {Aggregator[]}
 * @exception {FailedToGetAggregator}
 */
export async function getActiveAggregators({
  chain,
  logger
}: {
  chain: string
  logger: Logger
}): Promise<IAggregator[]> {
  try {
    const url = new URL(AGGREGATOR_ENDPOINT)
    url.searchParams.append('active', 'true')
    url.searchParams.append('chain', chain)
    const response = (await axios.get(url.toString()))?.data
    return response
  } catch (e) {
    logger.error(e)
    throw new OraklError(OraklErrorCode.FailedToGetAggregator)
  }
}

/**
 * Get `Aggregator` from `Orakl API` given an aggregator hash and chain.
 *
 * @param {string} aggregator hash
 * @param {string} chain name
 * @param {Logger} logger
 * @return {Aggregator}
 * @exception {FailedToGetAggregator}
 */
export async function getAggregator({
  aggregatorHash,
  chain,
  logger
}: {
  aggregatorHash: string
  chain: string
  logger: Logger
}): Promise<IAggregator> {
  try {
    const url = buildUrl(AGGREGATOR_ENDPOINT, `${aggregatorHash}/${chain}`)
    const response = (await axios.get(url))?.data
    return response
  } catch (e) {
    logger.error(e)
    throw new OraklError(OraklErrorCode.FailedToGetAggregator)
  }
}
