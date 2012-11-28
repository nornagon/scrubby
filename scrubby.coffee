toRun = []
sources = {}

$values = {}
merge = (a,b) ->
  for k,v of b
    a[k] = v

prepare = (js, name) ->
  xfmd = xform js, name+' '
  merge $values, xfmd.values
  sources[name] = { orig: js, xfmd }
  toRun.push escodegen.generate xfmd.ast

hasRun = false
run = ->
  throw "can't dynamically load scrubbys yet" if hasRun
  hasRun = true
  window.eval escodegen.generate
    type: 'Program'
    body: [
      type: 'VariableDeclaration'
      kind: 'var'
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
                value: v.value
              kind: 'init'
            } for k, v of $values
          )
      ]
    ]
  for s in toRun
    window.eval s

load = (url, cb) ->
  xhr = if window.ActiveXObject
    new window.ActiveXObject('Microsoft.XMLHTTP')
  else
    new XMLHttpRequest()
  xhr.open 'GET', url, true
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      if xhr.status in [0, 200]
        prepare xhr.responseText, url
      else
        throw new Error "Could not load #{url}"
      cb() if cb
  xhr.send null

deltaForNumber = (n) ->
  # big ol' hax to get an approximately okay order-of-magnitude delta for
  # dragging a number around.
  # right now this has a tendency to make your number more specific all the
  # time, which might be problematic.
  return 1 if n is 0
  return 0.1 if n is 1

  lastDigit = (n) ->
    Math.round((n/10-Math.floor(n/10))*10)

  firstSig = (n) ->
    n = Math.abs(n)
    i = 0
    while lastDigit(n) is 0
      i++
      n /= 10
    i

  specificity = (n) ->
    s = 0
    loop
      abs = Math.abs(n)
      fraction = abs - Math.floor(abs)
      if fraction < 0.000001
        return s
      s++
      n = n * 10

  s = specificity n
  if s > 0
    Math.pow(10, -s)
  else
    n = Math.abs n
    Math.pow 10, Math.max 0, firstSig(n)-1

attachScrubber = (w, s) ->
  s.addEventListener 'mousedown', (e) ->
    e.preventDefault()
    mx = e.pageX; my = e.pageY
    originalValue = Number(s.textContent)
    delta = deltaForNumber originalValue
    w.document.documentElement.classList.add('dragging')

    moved = (e) ->
      e.preventDefault()
      d = Number((Math.round((e.pageX - mx)/2)*delta + originalValue).toFixed(5))
      s.textContent = d
      window.$values[s.value_id] = d
      window.scrubby.emit 'scrubbed'
    w.addEventListener('mousemove', moved)

    up = (e) ->
      w.removeEventListener('mousemove', moved)
      w.removeEventListener('mouseup', up)
      w.document.documentElement.classList.remove('dragging')
    w.addEventListener('mouseup', up)


makeScrubbingContext = (w, name) ->
  w.document.head.appendChild(document.createElement('style')).textContent = '''
    .scrub {
      cursor: ew-resize;
      border-bottom: 1px dashed blue;
    }
    html.dragging {
      cursor: ew-resize;
    }
  '''

  code_text = sources[name].orig
  curpos = 0
  newCode = w.document.createElement('pre')
  for i,val of sources[name].xfmd.values
    newCode.appendChild(document.createTextNode(code_text.substring(curpos, val.range[0])))
    scrubber = newCode.appendChild(document.createElement('span'))
    scrubber.textContent = window.$values[i]
    scrubber.className = 'scrub'
    scrubber.value_id = i
    attachScrubber w, scrubber
    curpos = val.range[1]
  newCode.appendChild(document.createTextNode(code_text.substring(curpos)))
  return newCode

makeScrubbyButton = (name) ->
  b = document.createElement('button')
  b.textContent = name.replace(location.origin+'/', '')
  b.onclick = ->
    bounds = 'left='+screenX+',top='+screenY+',width=600,height=500'
    w = window.open('','_blank','menubar=no,location=no,resizable=yes,scrollbars=yes,status=no,'+bounds)
    newCode = makeScrubbingContext w, name
    w.document.body.appendChild newCode
  b

runScripts = ->
  document.head.appendChild(document.createElement('style')).textContent = '''
    .scrubby-files {
      position: fixed;
      top: 4px;
      right: 4px;
      padding: 4px;
      border-radius: 2px;
      background: rgba(0,0,255,0.4);
    }
  '''
  scrubbyFiles = document.body.appendChild(document.createElement('div'))
  scrubbyFiles.className = 'scrubby-files'
  scripts = document.getElementsByTagName 'script'
  scrubbys = (s for s in scripts when s.type is 'text/scrubby')
  id = 1
  do execute = ->
    if scrubbys.length is 0
      run()
    script = scrubbys.shift()
    if script?.type is 'text/scrubby'
      if script.src
        scrubbyFiles.appendChild(makeScrubbyButton(script.src))
        load script.src, execute
      else
        name = 'inline#'+id++
        scrubbyFiles.appendChild(makeScrubbyButton(name))
        prepare script.innerHTML, name
        execute()
  null

# Listen for window load, both in browsers and in IE.
if window.addEventListener
  addEventListener 'DOMContentLoaded', runScripts, no
else
  attachEvent 'onload', runScripts

window.scrubby =
  on: (e, f) ->
    @_listeners ?= {}
    (@_listeners[e] ?= []).push f
  emit: (e, args...) ->
    return unless @_listeners[e]?
    l.call(undefined, args...) for l in @_listeners[e]
    null

  makeScrubbingFrame: (name) ->
    makeScrubbingContext window, name
