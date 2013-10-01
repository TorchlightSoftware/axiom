# instantiate our instance of postal, passing it its lodash dependency
_ = require 'lodash'
uuid = require 'uuid'

bus = require('postal')(_)

module.exports = bus
