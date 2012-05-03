sinon = require("sinon")
Store = require(__dirname + "/../lib/Store")
Backbone = require(__dirname + "/../lib/backbone-pg-hstore")
pg = require("pg")
Model = Backbone.Model.extend(table: "documents")
describe "Store::Delete", ->
  connectStub = undefined
  queryStub = undefined
  client = undefined
  model = undefined
  beforeEach ->
    queryStub = sinon.stub()
    client = query: queryStub
    connectStub = sinon.stub(pg, "connect")
    model = new Model(
      id: "0000-0000-0000-0000"
      fieldOne: "One"
      fieldTwo: "Two"
    )

  it "should execute a delete query", (done) ->
    model.destroy success: (model) ->
      expect(queryStub.args[0][0]).toEqual "DELETE FROM documents WHERE id = $1"
      done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null,
      rows: []

  it "should pass an id as the first parameter to the query", (done) ->
    model.destroy success: (model) ->
      params = queryStub.args[0][1]
      expect(params[0]).toEqual "0000-0000-0000-0000"
      done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null,
      rows: []

  it "should trigger the error callback on error", (done) ->
    model.destroy error: (model, err, options) ->
      expect(err).toEqual "Oops!"
      done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, "Oops!", null

  afterEach ->
    queryStub.reset()
    pg.connect.restore()
