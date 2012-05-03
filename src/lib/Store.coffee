Backbone = require("backbone")
util = require("util")
pg = require("pg")
uuid = require("node-uuid")

class Store

  constructor: (connection)->
    @connection = connection

  read: (model, options) ->
    table = model.table or new model.model().table
    query = "SELECT %s FROM %s %s"
    values = []
    clauses = []
    fields = []
    
    if model instanceof Backbone.Model and model.get("id")
      values.push model.get("id")
      clauses.push util.format("%s.id = $%d", table, values.length)
    
    if options.filter
      for key,val of options.filter
        obj = {}
        obj[key] = val
        values.push @toHstore(obj)
        clauses.push util.format("%s.doc @> $%d", table, values.length)
    
    if options.hasAny
      values.push JSON.stringify(options.hasAny).replace(/\[/g, "{").replace(/\]/g, "}")
      clauses.push util.format("%s.doc ?| $%d", table, values.length)
    
    if options.hasAll
      values.push JSON.stringify(options.hasAll).replace(/\[/g, "{").replace(/\]/g, "}")
      clauses.push util.format("%s.doc ?& $%d", table, values.length)
    
    if options.clauses
      for clause in options.clauses
        values.push clause[1]
        clauses.push util.format(clause[0], util.format("$%d", values.length))
    
    # transform the fields do the use table.doc->'name'
    if util.isArray(options.fields)
      fields.push util.format("%s.id", table)
      for field in options.fields
        fields.push util.format("%s.doc->'%s' as %s", table, field, field)

    # users need to be able to specify raw fields
    if options.rawFields
      for field in options.rawFields
        fields.push field
    
    # prepeare the query by adding the fields and clauses 
    fields = [ util.format("%s.*", table) ]  if fields.length < 1
    clauses = (if (clauses.length > 0) then "WHERE " + clauses.join(" AND ") else "")
    query = util.format(query, fields.join(","), table, clauses)
    
    # add the group by feature
    if util.isArray(options.groupBy)
      query += util.format(" GROUP BY %s", options.groupBy.join(", "))
      
      if util.isArray(options.having)
        having = " HAVING " + options.having[0].replace(/\$\d+/g, "$%d")
        if util.isArray(options.having[1])
          for val in options.having[1]
            values.push val
            having = util.format(having, values.length)
        query += having


    # There are two order by statements: orderBy and rawOrderBy. We are going to
    # setup the first order by which just specifies names from the hstore. The
    # the second order by (raw) is intened for queries where you've specified
    # rawFields.
    orderBy = []
    
    # add the order by statements
    if util.isArray(options.orderBy)
      for val in options.orderBy
        field = if util.isArray(val) then val[0] else val
        order = if util.isArray(val) then val[1] else 'ASC'
        values.push util.format("%s.doc->'%s' %s", table, field, order)
        orderBy.push util.format("$%d", values.length)

    # add the raw order by to the query
    if util.isArray(options.rawOrderBy)
      for val in options.rawOrderBy
        values.push val
        orderBy.push util.format("$%d", values.length)

    query += util.format(" ORDER BY %s", orderBy.join(", "))  if orderBy.length > 0

    # add the limit to the query
    if options.limit?
      values.push options.limit
      query = query + util.format(" LIMIT $%d", values.length)

    # add offset to the query
    if options.offset?
      values.push options.offset
      query = query + util.format(" OFFSET $%d", values.length)

    # get a Postgres client
    pg.connect @connection, (err, client) =>
      return options.error(err)  if err
      client.query query, values, (err, results) =>
        return options.error(err)  if err

        # we need to return return the rows if the 
        # request was not form a Backbone.Model
        if model instanceof Backbone.Collection and results.rows?
          data = for row in results.rows
            object = {}
        
            # if there are fields specified then we need to map those 
            # to the object.
            if options.fields and util.isArray(options.fields)
              for field in options.fields
                object[field] = row[field.toLowerCase()]
        
            # if the hstore object is presetn parse it
            else if row.doc
              object = @toObject(row.doc)
        
            # assume that a custom query was used
            else
              object = row
            object.id = row.id
            object
        
          # call the success callback with the data
          options.success data
        
        # for models we just need to return the parsed hstore
        else if model instanceof Backbone.Model and results.rows[0]?
          object = @toObject(results.rows[0].doc)
          options.success object

        # all else fails... return null
        else
          options.success null

  create: (model, options) ->
    query = util.format("INSERT INTO %s (id, doc) VALUES ($1, $2)", model.table)
    doc = @toHstore(model.toJSON())
    id = uuid.v4()
    pg.connect @connection, (err, client) ->
      return options.error(err)  if err
      client.query query, [ id, doc ], (err, info) ->
        return options.error(err)  if err
        model.id = id
        options.success model.toJSON()

  update: (model, options) ->
    query = util.format("UPDATE %s SET doc = $1 WHERE id = $2", model.table)
    values = []
    object = model.toJSON()
    delete object.id

    values.push @toHstore(object)
    values.push model.id
    pg.connect @connection, (err, client) ->
      return options.error(err)  if err
      client.query query, values, (err, info) ->
        return options.error(err)  if err
        options.success model.toJSON()

  delete: (model, options) ->
    query = util.format("DELETE FROM %s WHERE id = $1", model.table)
    values = [ model.id ]
    object = model.toJSON()
    pg.connect @connection, (err, client) ->
      return options.error(err)  if err
      client.query query, values, (err, info) ->
        return options.error(err)  if err
        options.success model.toJSON()

  createTable: (table, callback) ->
    query = util.format("CREATE TABLE %s ( id uuid, doc hstore, CONSTRAINT %s_pkey PRIMARY KEY (id) ); CREATE INDEX %s_doc_idx_gist ON %s USING gist(doc);", table, table, table, table)
    pg.connect @connection, (err, client) ->
      client.query query, callback

  toHstore: (object) ->
    elements = for key,val of object
      switch typeof val
        when "boolean"
          val = (if (val) then @quoteAndEscape("true") else @quoteAndEscape("false"))
        when "object"
          val = (if (val) then @quoteAndEscape(JSON.stringify(val)) else "NULL")
        when "null"
          val = "NULL"
        when "number"
          val = (if (isFinite(val)) then @quoteAndEscape(JSON.stringify(val)) else "NULL")
        else
          val = @quoteAndEscape(val)
      "\"" + key + "\"=>" + val
    elements.join ", "

  quoteAndEscape: (string) ->
    "\"" + String(string).replace(/"/g, "\\\"") + "\""

  toObject: (string) ->
    elements = string.replace(/", "/, "\"\u0000 \"").split(/\u0000 /)
    object = {}
    for val in elements
      matches = val.match(/^"(.+?)"\s*=>\s*"?(.+?)"?$/)
      key = matches[1]
      value = matches[2].replace(/\\"/g, "\"")
      try
        object[key] = JSON.parse(value)
      catch e
        object[key] = value
      object[key] = null  if object[key] is "NULL"
    object

module.exports = Store