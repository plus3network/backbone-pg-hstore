var sinon = require('sinon')
  , Store = require(__dirname+'/../lib/Store')
  , Backbone = require(__dirname+'/../backbone-pg-hstore')
  , pg    = require('pg')
  , uuid  = require('node-uuid')
  , Model = Backbone.Model.extend({ table: 'documents' })
  , Collection = Backbone.Collection.extend({ model: Model })


describe('Store::Read', function () {
    var connectStub, queryStub, client, collection;

    beforeEach(function () {
        queryStub = sinon.stub();
        client = { query: queryStub };
        connectStub = sinon.stub(pg, 'connect');
        collection = new Collection();
    });

    it('should allow you to specifiy which fields to return', function (done) {
        collection.fetch({
            fields: ['firstOne']
            , success: function (collection, options) {
                expect(queryStub.args[0][0]).toEqual("SELECT documents.id,documents.doc->'firstOne' as firstOne FROM documents ");
                done();
            }
        });

        connectStub.callArgWith(1, null, client);
        queryStub.callArgWith(2, null, { rows: [{ id:uuid.v4(), doc: '"firstOne"=>"One"' }] });
    });
    
    it('should allow you to specifiy rawFields', function (done) {
        collection.fetch({
            rawFields: ["count(documents.doc->'isActive') as total"]
            , success: function (collection, options) {
                expect(queryStub.args[0][0]).toEqual("SELECT count(documents.doc->'isActive') as total FROM documents ");
                done();
            }
        });

        connectStub.callArgWith(1, null, client);
        queryStub.callArgWith(2, null, { rows: [{ total: 1 }] });
    });

    it('should allow you to select rows that match a filter', function (done) {
    
        collection.fetch({
            filter: { firstOne: 'One' }
            , success: function (collection, options) {
                expect(queryStub.args[0][0]).toEqual("SELECT documents.* FROM documents WHERE documents.doc @> $1");
                expect(queryStub.args[0][1]).toEqual(['"firstOne"=>"One"']);
                done();
            }
        });

        connectStub.callArgWith(1, null, client);
        queryStub.callArgWith(2, null, { rows: [{ id:uuid.v4(), doc: '"firstOne"=>"One"' }] });
    });
    
    it('should allow you to select rows that contain any field', function (done) {
    
        collection.fetch({
            hasAny: ['firstOne', 'secondOne']
            , success: function (collection, options) {
                expect(queryStub.args[0][0]).toEqual("SELECT documents.* FROM documents WHERE documents.doc ?| $1");
                expect(queryStub.args[0][1]).toEqual(['{"firstOne","secondOne"}']);
                done();
            }
        });

        connectStub.callArgWith(1, null, client);
        queryStub.callArgWith(2, null, { rows: [{ id:uuid.v4(), doc: '"firstOne"=>"One"' }] });
    });
    
    it('should allow you to select rows that contain all field', function (done) {
    
        collection.fetch({
            hasAll: ['firstOne', 'secondOne']
            , success: function (collection, options) {
                expect(queryStub.args[0][0]).toEqual("SELECT documents.* FROM documents WHERE documents.doc ?& $1");
                expect(queryStub.args[0][1]).toEqual(['{"firstOne","secondOne"}']);
                done();
            }
        });

        connectStub.callArgWith(1, null, client);
        queryStub.callArgWith(2, null, { rows: [{ id:uuid.v4(), doc: '"firstOne"=>"One", "secondOne"=>"Second"' }] });
    });
    
    it('should allow you to select rows with a custom clause/value set', function (done) {
    
        collection.fetch({
            clauses: [["documents.doc->'firstOne' = %s", 1]]
            , success: function (collection, options) {
                expect(queryStub.args[0][0]).toEqual("SELECT documents.* FROM documents WHERE documents.doc->'firstOne' = $1");
                expect(queryStub.args[0][1]).toEqual([1]);
                done();
            }
        });

        connectStub.callArgWith(1, null, client);
        queryStub.callArgWith(2, null, { rows: [{ id:uuid.v4(), doc: '"firstOne"=>"1", "secondOne"=>"Second"' }] });
    });

    afterEach(function () {
        queryStub.reset();
        pg.connect.restore();
    });
});
