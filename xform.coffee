esprima = require 'esprima'
escodegen = require 'escodegen'

process.stdin.resume()
process.stdin.setEncoding 'utf8'

data = ''
process.stdin.on 'data', (chunk) ->
  data += chunk

process.stdin.on 'end', ->
  process.stdout.write escodegen.generate form data

form = (program) ->
  parsed = esprima.parse program

  $values = {}
  nextId = 1
  replace = (e) ->
    if e.type is 'Literal'
      id = nextId++
      $values[id] = e.value
      type: "MemberExpression"
      computed: true
      object:
        type: 'Identifier'
        name: '$values'
      property:
        type: 'Literal'
        value: ''+id
    else
      transform e, replace

  xformed = transform parsed, replace
  xformed.body.unshift
    type: 'VariableDeclaration'
    declarations: [
      type: 'VariableDeclarator'
      id: { type: 'Identifier', name: '$values' }
      init:
        type: 'ObjectExpression',
        properties: (
          {
            type: 'Property'
            key:
              type: 'Literal'
              value: k
            value:
              type: 'Literal'
              value: v
            kind: 'init'
          } for k, v of $values
        )
    ]
    kind: 'var'
  xformed


# calls |f| on each node in the AST |object|
transform = (object, f) ->
  if object instanceof Array
    newObject = []
    for v,i in object
      if typeof v is 'object' && v isnt null
        newObject[i] = f(v)
      else
        newObject[i] = v
  else
    newObject = {}
    for own key, value of object
      if typeof value is 'object' && value isnt null
        newObject[key] = f(value)
      else
        newObject[key] = value
  newObject
