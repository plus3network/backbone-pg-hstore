sinon = require("sinon")
Store = require(__dirname + "/../lib/Store")
Backbone = require(__dirname + "/../lib/backbone-pg-hstore")
pg = require("pg")
Model = Backbone.Model.extend(table: "documents")
describe "Store::Update", ->
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

  it "should execute an update query", (done) ->
    model.save null,
      success: (model) ->
        expect(queryStub.args[0][0]).toEqual "UPDATE documents SET doc = $1 WHERE id = $2"
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null,
      rows: []

  it "should pass an hstore as the first parameter to the query", (done) ->
    model.save null,
      success: (model) ->
        params = queryStub.args[0][1]
        expect(params[0]).toEqual "\"fieldOne\"=>\"One\", \"fieldTwo\"=>\"Two\""
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null,
      rows: []

  it "should pass an id as the second parameter to the query", (done) ->
    model.save null,
      success: (model) ->
        params = queryStub.args[0][1]
        expect(params[1]).toEqual "0000-0000-0000-0000"
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null,
      rows: []

  it "should trigger the error callback on error", (done) ->
    model.save null,
      error: (model, err, options) ->
        expect(err).toEqual "Oops!"
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, "Oops!", null

  afterEach ->
    queryStub.reset()
    pg.connect.restore()
