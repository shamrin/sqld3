# Usage: coffee parse_sql.coffee "SELECT field FROM table;"
# other SQL:
# "SELECT table.field, field2, table.*, * FROM table, table2;"
# "SELECT x || \" hi \" FROM t,t2;"

parser = require "./sql.js"

# pythonic helpers
repr = (arg) -> require('util').format '%j', arg
dict = (pairs) ->
    d = {}
    for [k, v] in pairs
        d[k] = v
    d
pprint = (arg) -> console.log require('util').inspect arg, false, null

tree = parser.parse(process.argv[2])

Object.getPrototypeOf(tree).toString = (spaces) ->
    if not spaces then spaces = ""

    value = (if this.value? then "=> #{repr this.value}" else '')
    string = spaces + this.name +  " <" + this.innerText() + "> " + value
    children = this.children
    index = 0

    for child in children
        if typeof child == "string"
            #string += "\n" + spaces + ' ' + child
        else
            string += "\n" + child.toString(spaces + ' ')

    return string

tree.traverse
    traversesTextNodes: false
    exitedNode: (node) ->
        node.value = switch node.name
            # {k1: v1, k2: v2}
            when 'column_ref', 'select_result', 'single_source', 'join_op',\
                 'sql_stmt', 'select_core'
                dict([c.name, c.value] for c in node.children when c.value?)

            # [{k1: v1}, {k2: v2}]
            when 'join_source', 'select_stmt', 'value', 'expr'
                for c in node.children when (c.value? and c.name != 'comma')
                    dict([[c.name, c.value]])

            # [v1, v2] - ignore child nodes names
            when 'select_results'
                for c in node.children when (c.value? and c.name != 'comma')
                    c.value

            # v - ignore single child node name
            when 'literal_value'
                node.children[0].value

            # commented out: code works, but complex (and not really needed?)
            #when 'expr' # collapse ...{expr: [{value: ...}]} to ...{value: ...}
            #    for c in node.children when (c.value? and c.name != 'comma')
            #                     console.log 'expr c', c.name, c.value
            #                     if c.name == 'expr' and c.value.length == 1 \
            #                                         and c.value[0]['value']?
            #                         c.value[0]
            #                     else
            #                         dict([[c.name, c.value]])

            # 'some_value'
            when 'table_name', 'column_name'
                node.children[0].children.join ''

            when 'binary_operator'
                node.children[1]

            # special values and literals
            when 'star', 'comma', 'string_literal'
                node.children.join ''

        if node.name == 'sql_stmt'
            pprint node.value
            #console.log node.toString()

