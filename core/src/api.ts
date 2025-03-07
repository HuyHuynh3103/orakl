import axios from 'axios'
import { Logger } from 'pino'
import { IVrfConfig } from './types'
import { ORAKL_NETWORK_API_URL } from './settings'
import { buildUrl } from './utils'
import { OraklError, OraklErrorCode } from './errors'

const FILE_NAME = import.meta.url

/**
 * Fetch all VRF keys from Orakl Network API given a `chain` name.
 *
 * @param {string} chain name
 * @param {pino.Logger} logger
 * @return {Promise<IListenerRawConfig[]>} raw listener configuration
 * @exception {GetVrfConfigRequestFailed}
 */
export async function getVrfConfig({
  chain,
  logger
}: {
  chain: string
  logger?: Logger
}): Promise<IVrfConfig> {
  try {
    const endpoint = buildUrl(ORAKL_NETWORK_API_URL, 'vrf')
    const vrfKeys = (await axios.get(endpoint, { data: { chain } }))?.data

    if (vrfKeys.length == 0) {
      throw new Error(`Found no VRF key for chain [${chain}]`)
    } else if (vrfKeys.length > 1) {
      throw new Error(`Found more than one VRF key for chain [${chain}]`)
    }

    return vrfKeys[0]
  } catch (e) {
    logger?.error({ name: 'getVrfConfig', file: FILE_NAME, ...e }, 'error')
    throw new OraklError(OraklErrorCode.GetVrfConfigRequestFailed)
  }
}
