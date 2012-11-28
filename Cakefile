{exec} = require 'child_process'

js = ['esprima', 'escodegen'].map (e) -> "node_modules/#{e}/#{e}.js"
all = ['xform.coffee', 'scrubby.coffee']
task 'build', 'Build scrubby.all.js', (options) ->
	exec "(cat #{js.join(' ')}; coffee -cp #{all.join(' ')}) > scrubby.all.js",
	  (err, stdout, stderr) ->
      throw err if err
      console.log stdout + stderr
