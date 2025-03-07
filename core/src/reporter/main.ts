import { parseArgs } from 'node:util'
import { buildLogger } from '../logger'
import { reporter as aggregatorReporter } from './aggregator'
import { reporter as vrfReporter } from './vrf'
import { reporter as requestResponseReporter } from './request-response'
import { launchHealthCheck } from '../health-check'
import { hookConsoleError } from '../utils'
import { IReporters } from './types'

const REPORTERS: IReporters = {
  AGGREGATOR: aggregatorReporter,
  VRF: vrfReporter,
  REQUEST_RESPONSE: requestResponseReporter
}

const LOGGER = buildLogger('reporter')

async function main() {
  hookConsoleError(LOGGER)
  const reporter = loadArgs()
  REPORTERS[reporter](LOGGER)
  launchHealthCheck()
}

function loadArgs(): string {
  const {
    values: { reporter }
  } = parseArgs({
    options: {
      reporter: {
        type: 'string'
      }
    }
  })

  if (!reporter) {
    throw Error('Missing --reporter argument.')
  }

  if (!Object.keys(REPORTERS).includes(reporter)) {
    throw Error(`${reporter} is not supported reporter.`)
  }

  return reporter
}

main().catch((error) => {
  LOGGER.error(error)
  process.exitCode = 1
})
