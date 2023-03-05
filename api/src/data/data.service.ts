import { Injectable } from '@nestjs/common'
import { Data, Prisma } from '@prisma/client'
import { PrismaService } from '../prisma.service'
import { DatumDto } from './dto/datum.dto'

@Injectable()
export class DataService {
  constructor(private prisma: PrismaService) {}

  async create(datumDto: DatumDto): Promise<Data> {
    const data: Prisma.DataUncheckedCreateInput = {
      round: datumDto.round,
      timestamp: datumDto.timestamp,
      value: datumDto.value,
      aggregatorId: datumDto.aggregator,
      feedId: datumDto.feed
    }
    return this.prisma.data.create({ data })
  }

  async findAll(params: {
    skip?: number
    take?: number
    cursor?: Prisma.DataWhereUniqueInput
    where?: Prisma.DataWhereInput
    orderBy?: Prisma.DataOrderByWithRelationInput
  }): Promise<Data[]> {
    const { skip, take, cursor, where, orderBy } = params
    return this.prisma.data.findMany({
      skip,
      take,
      cursor,
      where,
      orderBy
    })
  }

  async findOne(dataWhereUniqueInput: Prisma.DataWhereUniqueInput): Promise<Data | null> {
    return this.prisma.data.findUnique({
      where: dataWhereUniqueInput
    })
  }

  async remove(where: Prisma.DataWhereUniqueInput): Promise<Data> {
    return this.prisma.data.delete({
      where
    })
  }
}
