var vows = require('vows')
  , assert = require('assert')
  , Store  = require(__dirname+'/../lib/Store')

var suite = vows.describe('Store Class').addBatch({
    'conversions to hstore': {
        'should convert a string': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: 'string' });
            },
            'to a valid string': function (string) {
                assert.equal(string, '"sample"=>"string"');
            }
        }
        , 'should convert a quoted string': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: 'this has "quotes"' });
            },
            'to a valid string with escaped quotes': function (string) {
                assert.equal(string, '"sample"=>"this has \\"quotes\\""');
            }
        }
        , 'should convert a null value': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: null });
            },
            'to a NULL string': function (string) {
                assert.equal(string, '"sample"=>NULL');
            }
        }
        , 'should convert a number': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: 3000.0020 });
            },
            'to a valid string': function (string) {
                assert.equal(string, '"sample"=>"3000.002"');
            }
        }
        , 'should convert an object': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: { foo: "bar" } });
            },
            'to an escaped json object': function (string) {
                assert.equal(string, '"sample"=>"{\\"foo\\":\\"bar\\"}"');
            }
        }
        , 'should convert an array': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: ['foo','bar'] });
            },
            'to an escaped json array': function (string) {
                assert.equal(string, '"sample"=>"[\\"foo\\",\\"bar\\"]"');
            }
        }
        , 'should convert a boolean true': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: true });
            },
            'to a "true" string': function (string) {
                assert.equal(string, '"sample"=>"true"');
            }
        }
        , 'should convert a boolean false': {
            topic: function () {
                var store = new Store();
                return store.toHstore({ sample: false });
            },
            'to a "false" string': function (string) {
                assert.equal(string, '"sample"=>"false"');
            }
        }
    }
    , 'convertion to object': {
        'should convert a string': {
            topic: function () {
                var store = new Store();
                return store.toObject('"sample"=>"String"');
            },
            'to a string': function (object) {
                assert.equal(object.sample, 'String');
            }
        }
        , 'should convert a null': {
            topic: function () {
                var store = new Store();
                return store.toObject('"sample"=>NULL');
            },
            'to a null value': function (object) {
                assert.isNull(object.sample);
            }
        }
        , 'should convert a escaped string': {
            topic: function () {
                var store = new Store();
                return store.toObject('"sample"=>"this has \\"quotes\\""');
            },
            'to a string': function (object) {
                assert.equal(object.sample, 'this has "quotes"');
            }
        }
        , 'should convert a number': {
            topic: function () {
                var store = new Store();
                return store.toObject('"sample"=>"100.01"');
            },
            'to a number': function (object) {
                assert.equal(object.sample, 100.01);
            }
        }
        , 'should convert an object': {
            topic: function () {
                var store = new Store();
                return store.toObject('"sample"=>"{\\"foo\\":\\"bar\\"}"');
            },
            'to a object': function (object) {
                assert.equal(object.sample.foo, 'bar');
            }
        }
        , 'should convert an array': {
            topic: function () {
                var store = new Store();
                return store.toObject('"sample"=>"[\\"foo\\",\\"bar\\"]"');
            },
            'to a array': function (object) {
                assert.isArray(object.sample);
                assert.include(object.sample, 'bar');
            }
        }
        , 'should convert boolean': {
            topic: function () {
                var store = new Store();
                return store.toObject('"isTrue"=>"true", "isFalse"=>"false"');
            },
            'to a boolean': function (object) {
                assert.isTrue(object.isTrue);
                assert.isFalse(object.isFalse);
            }
        }
    }
}).export(module);
