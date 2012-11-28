(function() {
  var xform;
  var __hasProp = Object.prototype.hasOwnProperty;
  xform = function(code, prefix) {
    var $values, nextId, parsed, replace, transform, xformed;
    if (prefix == null) {
      prefix = '';
    }
    parsed = esprima.parse(code, {
      range: true
    });
    $values = {};
    nextId = 1;
    replace = function(e) {
      var id;
      if (e.type === 'Literal' && typeof e.value === 'number') {
        id = nextId++;
        $values[prefix + id] = {
          value: e.value,
          range: e.range
        };
        return {
          type: "MemberExpression",
          computed: true,
          object: {
            type: 'Identifier',
            name: '$values'
          },
          property: {
            type: 'Literal',
            value: prefix + '' + id
          }
        };
      } else {
        return transform(e, replace);
      }
    };
    transform = function(object, f) {
      var i, key, newObject, v, value, _len;
      if (object instanceof Array) {
        newObject = [];
        for (i = 0, _len = object.length; i < _len; i++) {
          v = object[i];
          if (typeof v === 'object' && v !== null) {
            newObject[i] = f(v);
          } else {
            newObject[i] = v;
          }
        }
      } else {
        newObject = {};
        for (key in object) {
          if (!__hasProp.call(object, key)) continue;
          value = object[key];
          if (typeof value === 'object' && value !== null) {
            newObject[key] = f(value);
          } else {
            newObject[key] = value;
          }
        }
      }
      return newObject;
    };
    xformed = transform(parsed, replace);
    return {
      ast: xformed,
      values: $values
    };
  };
  window.xform = xform;
}).call(this);
