import { VersioningType, RequestMethod } from '@nestjs/common'

export function setAppSettings(app) {
  app.setGlobalPrefix('api')
  app.enableVersioning({
    type: VersioningType.URI
  })
}
