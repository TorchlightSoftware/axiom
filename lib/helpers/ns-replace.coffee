module.exports = (channel, from, to) ->
  target = channel.replace from, to

  # sort of hackish, ensures namespace will be valid
  unless target.indexOf('.') > 0
    target = target.replace '/', '.'

  return target
