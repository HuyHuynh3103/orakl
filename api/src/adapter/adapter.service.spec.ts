import { Test, TestingModule } from '@nestjs/testing'
import { AdapterService } from './adapter.service'
import { PrismaService } from '../prisma.service'

describe('AdapterService', () => {
  let adapter: AdapterService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AdapterService, PrismaService]
    }).compile()

    adapter = module.get<AdapterService>(AdapterService)
  })

  it('should be defined', () => {
    expect(adapter).toBeDefined()
  })

  it('should insert adapter and find it', async () => {
    const feeds = [
      {
        name: 'Binance-BTC-USD',
        definition: {
          url: 'https://api.binance.us/api/v3/ticker/price?symbol=BTCUSD',
          headers: {
            'Content-Type': 'application/json'
          },
          method: 'GET',
          reducers: [
            {
              function: 'PARSE',
              args: ['price']
            },
            {
              function: 'POW10',
              args: 8
            },
            {
              function: 'ROUND'
            }
          ]
        }
      }
    ]

    const { id } = await adapter.create({
      adapterHash: '0xe63985ed9d9aae887bdcfa03b53a1bea6fd1acc58b8cd51a9a69ede43eac6235',
      name: 'BTC-USD',
      decimals: 8,
      feeds
    })

    const adapterObj = await adapter.findOne({ id })
    expect(adapterObj.feeds.length).toBe(1)

    // Cleanup
    await adapter.remove({ id })
  })
})
