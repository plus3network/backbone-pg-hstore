sinon = require("sinon")
Store = require(__dirname + "/../lib/Store")
Backbone = require(__dirname + "/../lib/backbone-pg-hstore")
pg = require("pg")
uuid = require("node-uuid")
Model = Backbone.Model.extend(table: "documents")
Collection = Backbone.Collection.extend(model: Model)

describe "Store::Read", ->
  connectStub = undefined
  queryStub = undefined
  client = undefined
  collection = undefined

  beforeEach ->
    queryStub = sinon.stub()
    client = query: queryStub
    connectStub = sinon.stub(pg, "connect")
    collection = new Collection()

  it "should select a row by id for models", (done) ->
    id = uuid.v4()
    model = new Model(id: id)
    model.fetch success: (model, options) ->
      expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents WHERE documents.id = $1"
      expect(queryStub.args[0][1]).toEqual [ id ]
      done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: id, doc: "\"firstOne\"=>\"One\""}]}

  it "should allow you to specifiy which fields to return", (done) ->
    collection.fetch
      fields: [ "firstOne" ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.id,documents.doc->'firstOne' as firstOne FROM documents "
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\""}]}

  it "should allow you to specifiy rawFields", (done) ->
    collection.fetch
      rawFields: [ "count(documents.doc->'isActive') as total" ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT count(documents.doc->'isActive') as total FROM documents "
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null,
      rows: [ total: 1 ]

  it "should allow you to select rows that match a filter", (done) ->
    collection.fetch
      filter:
        firstOne: "One"

      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents WHERE documents.doc @> $1"
        expect(queryStub.args[0][1]).toEqual [ "\"firstOne\"=>\"One\"" ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\""}]}

  it "should allow you to select rows that contain any field", (done) ->
    collection.fetch
      hasAny: [ "firstOne", "secondOne" ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents WHERE documents.doc ?| $1"
        expect(queryStub.args[0][1]).toEqual [ "{\"firstOne\",\"secondOne\"}" ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to select rows that contain all field", (done) ->
    collection.fetch
      hasAll: [ "firstOne", "secondOne" ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents WHERE documents.doc ?& $1"
        expect(queryStub.args[0][1]).toEqual [ "{\"firstOne\",\"secondOne\"}" ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to select rows with a custom clause/value set", (done) ->
    collection.fetch
      clauses: [ [ "documents.doc->'firstOne' = %s", 1 ] ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents WHERE documents.doc->'firstOne' = $1"
        expect(queryStub.args[0][1]).toEqual [ 1 ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to limit the rows returned", (done) ->
    collection.fetch
      limit: 20
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents  LIMIT $1"
        expect(queryStub.args[0][1]).toEqual [ 20 ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to offset the rows returned", (done) ->
    collection.fetch
      offset: 0
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents  OFFSET $1"
        expect(queryStub.args[0][1]).toEqual [ 0 ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to order the rows returned", (done) ->
    collection.fetch
      orderBy: [ "createdOn", [ "firstOne", "DESC" ] ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents  ORDER BY $1, $2"
        expect(queryStub.args[0][1]).toEqual [ "documents.doc->'createdOn' ASC", "documents.doc->'firstOne' DESC" ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to order the rows returned with rawOrderBy", (done) ->
    collection.fetch
      rawOrderBy: [ "createdBy DESC", "createdOn DESC" ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents  ORDER BY $1, $2"
        expect(queryStub.args[0][1]).toEqual [ "createdBy DESC", "createdOn DESC" ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to group by a field", (done) ->
    collection.fetch
      groupBy: [ "count", "id" ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents  GROUP BY count, id"
        expect(queryStub.args[0][1]).toEqual [ ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should allow you to group by a field with a having clause", (done) ->
    collection.fetch
      groupBy: [ "count", "id" ]
      having: [ "count > $1 AND count < $2", [ 10, 20 ] ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.* FROM documents  GROUP BY count, id HAVING count > $1 AND count < $2"
        expect(queryStub.args[0][1]).toEqual [ 10, 20 ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  it "should create a valid query with everything", (done) ->
    collection.fetch
      fields: ["firstOne","secondOne"]
      filter:
        firstOne: "One"
      hasAll: ["firstOne","secondOne"]
      hasAny: ["isActive"]
      clauses: [ [ "documents.doc->'firstOne' = %s", 1 ] ]
      rawFields: [ "count(documents.doc->'isActive') as total" ]
      offset: 0
      limit: 25
      orderBy: [ "createdOn", [ "firstOne", "DESC" ] ]
      rawOrderBy: [ "createdBy DESC", "createdOn DESC" ]
      groupBy: [ "count", "id" ]
      having: [ "count > $1 AND count < $2", [ 10, 20 ] ]
      success: (collection, options) ->
        expect(queryStub.args[0][0]).toEqual "SELECT documents.id,documents.doc->'firstOne' as firstOne,documents.doc->'secondOne' as secondOne,count(documents.doc->'isActive') as total FROM documents WHERE documents.doc @> $1 AND documents.doc ?| $2 AND documents.doc ?& $3 AND documents.doc->'firstOne' = $4 GROUP BY count, id HAVING count > $5 AND count < $6 ORDER BY $7, $8, $9, $10 LIMIT $11 OFFSET $12"
        expect(queryStub.args[0][1]).toEqual [ '"firstOne"=>"One"', '{"isActive"}', '{"firstOne","secondOne"}', 1, 10, 20, "documents.doc->'createdOn' ASC", "documents.doc->'firstOne' DESC", 'createdBy DESC', 'createdOn DESC', 25, 0 ]
        done()

    connectStub.callArgWith 1, null, client
    queryStub.callArgWith 2, null, {rows: [{ id: uuid.v4(), doc: "\"firstOne\"=>\"One\", \"secondOne\"=>\"Second\""}]}

  afterEach ->
    queryStub.reset()
    pg.connect.restore()
  
