var Backbone = require('backbone')
    Store    = require(__dirname+'/lib/Store')



Backbone.createClient = function (options) {
    Backbone.connection = options;
}

Backbone.createTable = function (table, callback) {
    var store = new Store(Backbone.connection);
    store.createTable(table, callback);
}

Backbone.sync = function (method, model, options) {
    var store = new Store(Backbone.connection);
    return store[method](model, options);
}

module.exports = Backbone;
