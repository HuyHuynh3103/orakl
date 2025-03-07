import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { JobModule } from './job/job.module'
import { BullModule } from '@nestjs/bullmq'
import { AppController } from './app.controller'
import { AppService } from './app.service'
import { ConfigService } from '@nestjs/config'

@Module({
  imports: [
    JobModule,
    ConfigModule.forRoot({
      isGlobal: true
    }),
    BullModule
  ],
  controllers: [AppController],
  providers: [AppService, ConfigService]
})
export class AppModule {}
