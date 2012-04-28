var  _       = require(__dirname+'/../node_modules/backbone/node_modules/underscore')
  , Backbone = require(__dirname+'/../node_modules/backbone')
  , util     = require('util')
  , pg       = require('pg')
  , uuid     = require('node-uuid')

var Store = function (connection) {
    this.connection = connection;
}


Store.prototype.read = function (model, options) {

    var table      = model.table || new model.model().table
      , query      = 'SELECT %s FROM %s %s'
      , values     = []
      , clauses    = []
      , fields     = ['*']
      , _this      = this
      , returnRows = true;
    
    if(model instanceof Backbone.Model && model.get('id')) {
        values.push(model.get('id'));
        clauses.push(util.format('%s.id = $%d', table, values.length));
        returnRows = false;
    }

    if(options.with) {
        _.each(options.with, function (val, key) {
            var obj = {};
            obj[key]=val;
            values.push(_this.toHstore(obj));
            clauses.push(util.format('%s.doc @> $%d', table, values.length));
        });
    }

    if(options.hasAny) {
        values.push(JSON.stringify(options.hasAny).replace(/\[/g, "{").replace(/\]/g, '}'));
        clauses.push(util.format('%s.doc ?| $%d', table, values.length));
    }
    
    if(options.hasAll) {
        values.push(JSON.stringify(options.hasAll).replace(/\[/g, "{").replace(/\]/g, '}'));
        clauses.push(util.format('%s.doc ?& $%d', table, values.length));
    }

    if(util.isArray(options.fields)) {
        fields = [util.format('%s.id', table)];
        options.fields.forEach(function (field) {
            fields.push(util.format("%s.doc->'%s' as %s", table, field, field));
        });
    }

    clauses = (clauses.length > 0)? 'WHERE '+clauses.join(' AND ') : '';
    query = util.format(query, fields.join(','), table, clauses);
    console.log("Query:", query);
    console.log("Values:", values);
    
    pg.connect(this.connection, function (err, client) {
        client.query(query, values, function (err, results) {
            if(err) {
                return options.error(err);
            }

            if(returnRows) {
                // Loop through each row and parse the doc
                var data = [];
                results.rows.forEach(function (row) {
                    var object = {};
                    if(options.fields && util.isArray(options.fields)) {
                        console.log(options.fields, row);
                        options.fields.forEach(function (field) {
                            // pgsql returns the field names as lowercase.
                            object[field] = row[field.toLowerCase()];
                        });    
                    } else {
                        object = _this.toObject(row.doc);
                    }
                    object.id = row.id;
                    data.push(object);
                });
                // Pass the data using the callback
                options.success(data);
            } else if(results.rows[0]){
                var object = _this.toObject(results.rows[0].doc);
                options.success(object);
            } else {
                options.success(null);
            }

        });
    });
}

Store.prototype.create = function (model, options) {

    var query      = util.format('INSERT INTO %s (id, doc) VALUES ($1, $2)', model.table)
      , _this      = this
      , doc        = this.toHstore(model.toJSON())
      , id         = uuid.v4()

    pg.connect(this.connection, function (err, client) {
        client.query(query, [id, doc], function (err, info) {
            if(err) {
                return options.error(err);
            }
            
            model.id = id;
            options.success(model.toJSON());
        });
    });
}

Store.prototype.update = function (model, options) {

}

Store.prototype.delete = function (model, options) {

}

Store.prototype.createTable = function (table, callback) {
    query = util.format("CREATE TABLE %s ( id uuid, doc hstore, CONSTRAINT %s_pkey PRIMARY KEY (id) ); CREATE INDEX %s_doc_idx_gist ON %s USING gist(doc);", table, table, table, table);
    console.log(query);
    pg.connect(this.connection, function (err, client) {
        client.query(query, callback);
    });
}

Store.prototype.toHstore = function (object) {
    var elements = []
    _.each(object, function (val, key) {
        switch (typeof val) {
            case 'boolean':
                val = (val)? this.quoteAndEscape('true') : this.quoteAndEscape('false');
                break;
            case 'object':
                val = (val)? this.quoteAndEscape(JSON.stringify(val)) : 'NULL';
                break;
            case 'null':
                val = 'NULL'
                break;
            case 'number':
                val = (isFinite(val))? this.quoteAndEscape(JSON.stringify(val)) : 'NULL';
                break;
            default:
                val = this.quoteAndEscape(val);
        }
        elements.push('"'+key+'"=>'+val);
    }, this);
    return elements.join(', ');
}

Store.prototype.quoteAndEscape = function (string) {
    return '"'+String(string).replace(/"/g, '\\"')+'"'
}

Store.prototype.toObject = function (string) {
    var elements = string.split(/, /)
      , object = {};

    elements.forEach(function (val) {
        var matches = val.match(/^"(.+?)"\s*=>\s*"?(.+?)"?$/)
          , key     = matches[1]
          , value   = matches[2].replace(/\\"/g, '"')

        // Try to use JSON to parse the value
        try {
            object[key] = JSON.parse(value);
        // Catch the errors which are usually strings
        } catch(e) {
            object[key] = value;
        }

        // If we get a NULL then let's make it null
        if(object[key] === 'NULL') {
            object[key] = null;
        }
    });

    return object;
}

module.exports = Store;
