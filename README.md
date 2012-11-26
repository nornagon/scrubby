JavaScript source transformation to support [Bret Victor](http://vimeo.com/36579366)-style value-scrubbing interfaces with the information without having to recompile code every time the value changes.

[Try it out](http://libris.nornagon.net/jca/scrubby/scrubby.html)!

Transforms this JavaScript:

```javascript
var x = 20, y = 32
ctx.moveTo(x,y)
ctx.lineTo(x+50, y)
```

into this:

```javascript
var $values = {
        '1': 20,
        '2': 32,
        '3': 50
    };
var x = $values['1'], y = $values['2'];
ctx.moveTo(x, y);
ctx.lineTo(x + $values['3'], y);
```
