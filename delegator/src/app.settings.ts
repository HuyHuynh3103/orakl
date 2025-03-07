import { VersioningType, RequestMethod } from '@nestjs/common'

export function setAppSettings(app) {
  app.setGlobalPrefix('api', {
    exclude: [{ path: 'health', method: RequestMethod.GET }]
  })
  app.enableVersioning({
    type: VersioningType.URI
  })
}
