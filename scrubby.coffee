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

attachScrubber = (w, s) ->
  s.addEventListener 'mousedown', (e) ->
    e.preventDefault()
    mx = e.pageX; my = e.pageY
    originalValue = Number(s.innerText)
    w.document.documentElement.classList.add('dragging')

    moved = (e) ->
      e.preventDefault()
      d = Math.floor((e.pageX - mx)/2) + originalValue
      s.innerText = d
      window.$values[s.value_id] = d
      onValueScrubbed()
    w.addEventListener('mousemove', moved)

    up = (e) ->
      w.removeEventListener('mousemove', moved)
      w.removeEventListener('mouseup', up)
      w.document.documentElement.classList.remove('dragging')
    w.addEventListener('mouseup', up)

makeScrubbyButton = (name) ->
  b = document.createElement('button')
  b.innerText = name.replace(location.origin+'/', '')
  b.onclick = ->
    bounds = 'left='+screenX+',top='+screenY+',width=400,height=500'
    w = window.open('','_blank','menubar=no,location=no,resizable=yes,scrollbars=yes,status=no,'+bounds)
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
      newCode.appendChild(document.createTextNode(
          code_text.substring(curpos, val.range[0])))
      scrubber = newCode.appendChild(document.createElement('span'))
      scrubber.innerText = val.value # TODO actually use current value
      scrubber.className = 'scrub'
      scrubber.value_id = i
      attachScrubber w, scrubber
      curpos = val.range[1]
    newCode.appendChild(document.createTextNode(
        code_text.substring(curpos)))
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
