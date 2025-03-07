import { ValidationPipe } from '@nestjs/common'
import { NestFactory } from '@nestjs/core'
import { AppModule } from './app.module'
import { setAppSettings } from './app.settings'
import { ConfigService } from '@nestjs/config'
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger'

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore: Unreachable code error
BigInt.prototype.toJSON = function (): string {
  return this.toString()
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule)
  setAppSettings(app)
  app.useGlobalPipes(new ValidationPipe({ whitelist: false, transform: true }))

  const version = '1.0'
  const config = new DocumentBuilder()
    .setTitle('Orakl Network API')
    .setDescription('The Orakl Network API description')
    .setVersion(version)
    .build()
  const document = SwaggerModule.createDocument(app, config)
  SwaggerModule.setup('docs', app, document)

  const configService = app.get(ConfigService)
  const port = configService.get('APP_PORT')
  await app.listen(port)
}
bootstrap()
