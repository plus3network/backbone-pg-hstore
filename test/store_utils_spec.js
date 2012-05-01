var Store  = require(__dirname+'/../lib/Store')

describe("Store Utility Functions", function () {

    var store = new Store();
    
    it('should convert a hash with a string to hstore object', function () {
        expect(store.toHstore({ sample: 'string' })).toEqual('"sample"=>"string"');
    });

    it('should convert a hash with a qouted string to a hstore object', function () {
        expect(store.toHstore({ sample: 'this has "quotes"' })).toEqual('"sample"=>"this has \\"quotes\\""');
    });

    it('should convert a hash with a null value to a hstore object', function () {
        expect(store.toHstore({ sample: null })).toEqual('"sample"=>NULL');
    });

    it('should convert a hash with a number to a valid object', function () {
        expect(store.toHstore({ sample: 3000.0020 })).toEqual('"sample"=>"3000.002"'); 
    });

    it('should convert a hash with an object to a valid object', function () {
        expect(store.toHstore({ sample: { foo: "bar" } })).toEqual('"sample"=>"{\\"foo\\":\\"bar\\"}"');
    });

    it('should convert a hash with an array to a valid object', function () {
        expect(store.toHstore({ sample: ['foo','bar'] })).toEqual('"sample"=>"[\\"foo\\",\\"bar\\"]"');
    });

    it('should convert a hash with a boolean true to a hstore object', function () {
        expect(store.toHstore({ sample: true })).toEqual('"sample"=>"true"');
    });

    it('should convert a hash with a boolean false to a hstore object', function () {
        expect(store.toHstore({ sample: false })).toEqual('"sample"=>"false"');
    });

    it('should convert a hstore object with a string to an object', function () {
        expect(store.toObject('"sample"=>"String"').sample).toEqual('String'); 
    });

    it('should convert a hstore object with a null value to an object', function () {
        expect(store.toObject('"sample"=>NULL').sample).toBeNull();
    });

    it('should covert a hstore object with an escaped string to an object', function () {
        expect(store.toObject('"sample"=>"this has \\"quotes\\""').sample).toEqual('this has "quotes"');
    });

    it('should convert a hstore object with a comma', function () {
        expect(store.toObject('"sample"=>"This bar, no that bar"').sample).toEqual('This bar, no that bar');
    });

    it('should convert a hstore object with a number to an object', function () {
        expect(store.toObject('"sample"=>"100.01"').sample).toEqual(100.01);
    });

    it('should convert a hstore object with an object to an object', function () {
        expect(store.toObject('"sample"=>"{\\"foo\\":\\"bar\\"}"').sample.foo).toEqual('bar');
    });

    it('should convert a hstore object with an array to an object', function () {
        expect(store.toObject('"sample"=>"[\\"foo\\",\\"bar\\"]"').sample[0]).toEqual('foo');
    });

    it('should convert a hstore object with booleans to an object', function () {
        var object = store.toObject('"isTrue"=>"true", "isFalse"=>"false"');
        expect(object.isTrue).toBeTruthy();
        expect(object.isFalse).toBeFalsy();
    });
});
