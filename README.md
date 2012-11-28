JavaScript source transformation to support [Bret Victor](http://vimeo.com/36579366)-style value-scrubbing interfaces with the information without having to recompile code every time the value changes.

[Try it out](http://nornagon.github.com/scrubby)!

## API

To use scrubby in your project, just include `scrubby.all.js` in your page and
mark any scripts you want to scrub with `type=text/scrubby`.

```html
<!DOCTYPE html>
<script src='http://nornagon.github.com/scrubby/scrubby.all.js'></script>
<style>
  .ball {
    position: absolute;
    left: 100px; top: 100px;
    width: 50px; height: 50px;
    border-radius: 25px;
    background: green;
  }
</style>
<div class='ball'></div>
<script type='text/scrubby'>
var t = 0;
var lastFrame = Date.now();
setInterval(function() {
  var ball = document.querySelector('.ball');
  var now = Date.now(), dt = (now - lastFrame) / 1000 * 40;
  t += dt; lastFrame = now;
  ball.style.left = 100 + 50 * Math.sin(t * 0.2) + 'px';
  ball.style.top = 100 + 50 * Math.sin(t * 0.2 + 0.4 * Math.PI*2) + 'px';
}, 1000/60);
</script>
```

(See this example [live](http://nornagon.github.com/scrubby/example.html).)

Scrubby adds a button to the top-left of the page for each script you specify that's scrubbable. Clicking on that button will open a new window with the code in it, and you can scrub live immediately.

Note that in this code, scrubbing the framerate (`1000/60`) does nothing, because the `setInterval` has already been called by the time you start scrubbing. Scrubbing will only work on values that are referenced again after you edit them.

If you want to re-run a piece of code when a value is scrubbed, you can listen for the `'scrubbed'` event:

```javascript
scrubby.on('scrubbed', function() {
  redraw()
})
```

(the [demo code](http://nornagon.github.com/scrubby) does this to update the canvas when you edit a value.)

## How it works

Scrubby transforms this JavaScript:

```javascript
function draw() {
  var x = 20, y = 32
  ctx.moveTo(x,y)
  ctx.lineTo(x+50, y)
}
```

into this:

```javascript
var $values = {
  '1': 20,
  '2': 32,
  '3': 50
};
function draw() {
  var x = $values['1'], y = $values['2'];
  ctx.moveTo(x, y);
  ctx.lineTo(x + $values['3'], y);
}
```

When you scrub a value, scrubby updates the global `$values` object with the edited value. When the code runs again, it automatically uses the new value.

## TODO

- It would be nice to be able to type in a value, as well as to scrub it.
- Editing strings would be good.
- Strings like 'hsla(260,40%,40%,0.1)' could have a color picker attached instead of a text editor.
- I'd like to explore indirecting not just values, but whole functions, allowing you to edit the text of a function. I'm worried that it'll break in non-obvious ways, though. The current method is very straightforward, and I'd like to preserve that.