(function() {
  var $values, attachScrubber, deltaForNumber, hasRun, load, makeScrubbingContext, makeScrubbyButton, merge, prepare, run, runScripts, sources, toRun;
  var __slice = Array.prototype.slice;
  toRun = [];
  sources = {};
  $values = {};
  merge = function(a, b) {
    var k, v, _results;
    _results = [];
    for (k in b) {
      v = b[k];
      _results.push(a[k] = v);
    }
    return _results;
  };
  prepare = function(js, name) {
    var xfmd;
    xfmd = xform(js, name + ' ');
    merge($values, xfmd.values);
    sources[name] = {
      orig: js,
      xfmd: xfmd
    };
    return toRun.push(escodegen.generate(xfmd.ast));
  };
  hasRun = false;
  run = function() {
    var k, s, v, _i, _len, _results;
    if (hasRun) {
      throw "can't dynamically load scrubbys yet";
    }
    hasRun = true;
    window.eval(escodegen.generate({
      type: 'Program',
      body: [
        {
          type: 'VariableDeclaration',
          kind: 'var',
          declarations: [
            {
              type: 'VariableDeclarator',
              id: {
                type: 'Identifier',
                name: '$values'
              },
              init: {
                type: 'ObjectExpression',
                properties: (function() {
                  var _results;
                  _results = [];
                  for (k in $values) {
                    v = $values[k];
                    _results.push({
                      type: 'Property',
                      key: {
                        type: 'Literal',
                        value: k
                      },
                      value: {
                        type: 'Literal',
                        value: v.value
                      },
                      kind: 'init'
                    });
                  }
                  return _results;
                })()
              }
            }
          ]
        }
      ]
    }));
    _results = [];
    for (_i = 0, _len = toRun.length; _i < _len; _i++) {
      s = toRun[_i];
      _results.push(window.eval(s));
    }
    return _results;
  };
  load = function(url, cb) {
    var xhr;
    xhr = window.ActiveXObject ? new window.ActiveXObject('Microsoft.XMLHTTP') : new XMLHttpRequest();
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      var _ref;
      if (xhr.readyState === 4) {
        if ((_ref = xhr.status) === 0 || _ref === 200) {
          prepare(xhr.responseText, url);
        } else {
          throw new Error("Could not load " + url);
        }
        if (cb) {
          return cb();
        }
      }
    };
    return xhr.send(null);
  };
  deltaForNumber = function(n) {
    var firstSig, lastDigit, s, specificity;
    if (n === 0) {
      return 1;
    }
    if (n === 1) {
      return 0.1;
    }
    lastDigit = function(n) {
      return Math.round((n / 10 - Math.floor(n / 10)) * 10);
    };
    firstSig = function(n) {
      var i;
      n = Math.abs(n);
      i = 0;
      while (lastDigit(n) === 0) {
        i++;
        n /= 10;
      }
      return i;
    };
    specificity = function(n) {
      var abs, fraction, s, _results;
      s = 0;
      _results = [];
      while (true) {
        abs = Math.abs(n);
        fraction = abs - Math.floor(abs);
        if (fraction < 0.000001) {
          return s;
        }
        s++;
        _results.push(n = n * 10);
      }
      return _results;
    };
    s = specificity(n);
    if (s > 0) {
      return Math.pow(10, -s);
    } else {
      n = Math.abs(n);
      return Math.pow(10, Math.max(0, firstSig(n) - 1));
    }
  };
  attachScrubber = function(w, s) {
    return s.addEventListener('mousedown', function(e) {
      var delta, moved, mx, my, originalValue, up;
      e.preventDefault();
      mx = e.pageX;
      my = e.pageY;
      originalValue = Number(s.innerText);
      delta = deltaForNumber(originalValue);
      w.document.documentElement.classList.add('dragging');
      moved = function(e) {
        var d;
        e.preventDefault();
        d = Number((Math.round((e.pageX - mx) / 2) * delta + originalValue).toFixed(5));
        s.innerText = d;
        window.$values[s.value_id] = d;
        return window.scrubby.emit('scrubbed');
      };
      w.addEventListener('mousemove', moved);
      up = function(e) {
        w.removeEventListener('mousemove', moved);
        w.removeEventListener('mouseup', up);
        return w.document.documentElement.classList.remove('dragging');
      };
      return w.addEventListener('mouseup', up);
    });
  };
  makeScrubbingContext = function(w, name) {
    var code_text, curpos, i, newCode, scrubber, val, _ref;
    w.document.head.appendChild(document.createElement('style')).textContent = '.scrub {\n  cursor: ew-resize;\n  border-bottom: 1px dashed blue;\n}\nhtml.dragging {\n  cursor: ew-resize;\n}';
    code_text = sources[name].orig;
    curpos = 0;
    newCode = w.document.createElement('pre');
    _ref = sources[name].xfmd.values;
    for (i in _ref) {
      val = _ref[i];
      newCode.appendChild(document.createTextNode(code_text.substring(curpos, val.range[0])));
      scrubber = newCode.appendChild(document.createElement('span'));
      scrubber.innerText = window.$values[i];
      scrubber.className = 'scrub';
      scrubber.value_id = i;
      attachScrubber(w, scrubber);
      curpos = val.range[1];
    }
    newCode.appendChild(document.createTextNode(code_text.substring(curpos)));
    return newCode;
  };
  makeScrubbyButton = function(name) {
    var b;
    b = document.createElement('button');
    b.innerText = name.replace(location.origin + '/', '');
    b.onclick = function() {
      var bounds, newCode, w;
      bounds = 'left=' + screenX + ',top=' + screenY + ',width=600,height=500';
      w = window.open('', '_blank', 'menubar=no,location=no,resizable=yes,scrollbars=yes,status=no,' + bounds);
      newCode = makeScrubbingContext(w, name);
      return w.document.body.appendChild(newCode);
    };
    return b;
  };
  runScripts = function() {
    var execute, id, s, scripts, scrubbyFiles, scrubbys;
    document.head.appendChild(document.createElement('style')).textContent = '.scrubby-files {\n  position: fixed;\n  top: 4px;\n  right: 4px;\n  padding: 4px;\n  border-radius: 2px;\n  background: rgba(0,0,255,0.4);\n}';
    scrubbyFiles = document.body.appendChild(document.createElement('div'));
    scrubbyFiles.className = 'scrubby-files';
    scripts = document.getElementsByTagName('script');
    scrubbys = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = scripts.length; _i < _len; _i++) {
        s = scripts[_i];
        if (s.type === 'text/scrubby') {
          _results.push(s);
        }
      }
      return _results;
    })();
    id = 1;
    (execute = function() {
      var name, script;
      if (scrubbys.length === 0) {
        run();
      }
      script = scrubbys.shift();
      if ((script != null ? script.type : void 0) === 'text/scrubby') {
        if (script.src) {
          scrubbyFiles.appendChild(makeScrubbyButton(script.src));
          return load(script.src, execute);
        } else {
          name = 'inline#' + id++;
          scrubbyFiles.appendChild(makeScrubbyButton(name));
          prepare(script.innerHTML, name);
          return execute();
        }
      }
    })();
    return null;
  };
  if (window.addEventListener) {
    addEventListener('DOMContentLoaded', runScripts, false);
  } else {
    attachEvent('onload', runScripts);
  }
  window.scrubby = {
    on: function(e, f) {
      var _base, _ref, _ref2;
            if ((_ref = this._listeners) != null) {
        _ref;
      } else {
        this._listeners = {};
      };
      return ((_ref2 = (_base = this._listeners)[e]) != null ? _ref2 : _base[e] = []).push(f);
    },
    emit: function() {
      var args, e, l, _i, _len, _ref;
      e = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (this._listeners[e] == null) {
        return;
      }
      _ref = this._listeners[e];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        l = _ref[_i];
        l.call.apply(l, [void 0].concat(__slice.call(args)));
      }
      return null;
    },
    makeScrubbingFrame: function(name) {
      return makeScrubbingContext(window, name);
    }
  };
}).call(this);
