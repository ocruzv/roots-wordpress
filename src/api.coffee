rest        = require('rest')
error_code  = require('rest/interceptor/errorCode')
mime        = require('rest/interceptor/mime')

module.exports = rest.wrap(mime, mime: 'application/json')
  .wrap(error_code)
