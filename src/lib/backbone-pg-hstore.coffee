Backbone = require("backbone")
Store = require(__dirname + "/Store")

Backbone.createClient = (options) ->
  Backbone.connection = options

Backbone.createTable = (table, callback) ->
  store = new Store(Backbone.connection)
  store.createTable table, callback

Backbone.sync = (method, model, options) ->
  store = new Store(Backbone.connection)
  store[method] model, options

module.exports = Backbone
