// Generated by CoffeeScript 1.3.1
(function() {
  var Backbone, Store;

  Backbone = require("backbone");

  Store = require(__dirname + "/Store");

  Backbone.createClient = function(options) {
    return Backbone.connection = options;
  };

  Backbone.createTable = function(table, callback) {
    var store;
    store = new Store(Backbone.connection);
    return store.createTable(table, callback);
  };

  Backbone.sync = function(method, model, options) {
    var store;
    store = new Store(Backbone.connection);
    return store[method](model, options);
  };

  module.exports = Backbone;

}).call(this);