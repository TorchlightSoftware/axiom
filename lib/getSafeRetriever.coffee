# limit an extension to retrieve things within
# its assigned folder
module.exports = (extensionName, retriever) ->

  return Object.freeze {
    root: retriever.rel('domain', extensionName)

    rel: retriever.rel

    retrieve: retriever.retrieve
  }
