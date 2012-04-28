backbone-pg-hstore
==================

A Backbone sync adapter that used Postgres Hstore for the backend. This library is intended to be used with Node.js.

### Example Usage:

```javascript
var Backbone = require('backbone-pg-hstore');

// Setup the connection details
Backbone.createClient({
      user: 'postgres'
    , database: 'postgres'
    , host: 'localhost'
});

// Create a table
Backbone.createTable('users', function (err, info) {
    
    // Create a model
    var UserModel = Backbone.Model.extend({ table: 'users' });

    // Create a new object
    var me = new UserModel({ firstName: "Chris", lastName: "Cowan", isActive: true });
    
    // Save your new object
    me.save(null, {
          
        // Success calback
        success: function (model) {
            // Do something here!
        }
        
        // Error callback
        , error: function (err) {
            // Oops!
        }
    });

    // Create a collection
    var UserCollection = Backbone.Collection.extend({ model: UserModel });

    // Lets fetch some users
    var users = new UserCollection();
    users.fetch({

        // You can choose to fetch some of the fields. If you omit this option
        // it will select all the fields from the hstore. Good if you only need
        // some of the fields in a large object. 
        fields: [ 'firstName', 'lastName' ]
        
        // rows have the match following key/values, useful for filtering
        , with: { lastName: 'Cowan', isActive: true }
        
        // rows needs to have any of these fields
        , hasAny: [ 'email' ]

        // rows must have ALL of these fields
        , hasAll: [ 'firstName', 'lastName' ]
        
        // Success callback
        , success: function (collection) {
            // Do something here!
        }

        // Error callback
        , error: function (err) {
            // Oops!
        }
    })

});
```

### Inspired By

http://blog.creapptives.com/post/14062057061/the-key-value-store-everyone-ignored-postgresql
