# instantiate our instance of postal, passing it its lodash dependency
_ = require 'lodash'
module.exports = require('postal')(_)
