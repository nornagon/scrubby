var obj = document.createElement('div')
obj.style.position = 'absolute'
obj.style.top = '100px'
obj.style.left = '100px'
obj.style.width = '10px';
obj.style.height = '10px';
obj.style.borderRadius = '5px';
obj.style.background = 'green';

document.body.appendChild(obj);

function frame() {
  var t = Date.now() / 1000;
  var A = 100,
      B = 200,
      a = 4,
      b = 2,
      d = Math.PI*2 * (180 / 360);
  obj.style.top = 300 + A * Math.sin(a * t + d) + 'px';
  obj.style.left = 300 + B * Math.sin(b * t) + 'px';
}
