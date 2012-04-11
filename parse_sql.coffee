# Usage: coffee parse_sql.coffee "SELECT field FROM table;"

parser = require "./sql.js"

tree = parser.parse(process.argv[2])

tree.traverse
    traversesTextNodes: false
    exitedNode: (node) ->
        console.log node.name, ((if c.name? then c.name else c) for c in node.children)

