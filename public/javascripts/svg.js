function SvgViewPane(container) {
  var svg = $(container).find('svg');
  var graph = svg.find('#graph1');

  if(graph.length === 0){
    throw "not found";
  }

  var transform = getTransform();

  //Prevent any kind of dragging
  $(container).bind('dragstart', function(e) {
    e.preventDefault();
    e.stopPropagation();
    return false;
  });

  if(!$.browser.mozilla) {
    //Chrome needs to adjust scale manually
    if($.browser.safari && /chrome/.test(navigator.userAgent.toLowerCase())) {
      var h = parseInt(svg.attr('height'));
      var w = parseInt(svg.attr('width'));
      if((350 / h) > (631 / w)) {
        graph.attr('transform', 'scale(' +(350 / h) + ') translate('+transform.translate.join(',') +')');
      } else {
        graph.attr('transform', 'scale(' +(631 / w) + ') translate('+transform.translate.join(',') +')');
      }
      //Reload transform
      transform = getTransform();
    }
    //Add background color for safari
    svg.attr('style', 'background-color:#EBE3D1');
    svg.removeAttr('height');
    svg.removeAttr('width');
    svg.removeAttr('viewBox');
  }

  //SVG moving
  var touchpoint = [0,0];
  var move = function(e) {
    var cords = [ e.pageX - touchpoint[0], e.pageY - touchpoint[1]];
    graph.attr('transform', 'scale('+transform.scale+') translate(' + (transform.translate[0] + Math.round(cords[0]/(30*transform.scale)*20))+ ', '+ (transform.translate[1] +  Math.round(cords[1]/(30*transform.scale)*20)) +')');
  };

  $(container).bind('mousedown', function(e) {
    touchpoint = [e.pageX, e.pageY];
    $(this).bind('mousemove', move);
    $(this).attr('style', 'cursor:hand;');
  });

  $(container).bind('mouseup', function(e) {
    $(this).unbind('mousemove',move);
    touchpoint = [0,0];
    transform = getTransform();
  });

  function getTransform() {
    var transform = graph.attr('transform');
    var transform_result = {}
    if(translate = /translate\(\s?([-+]?[0-9]*\.?[0-9]+)(?:\s?,\s?|\s)([-+]?[0-9]*\.?[0-9]+)\s?\)/.exec(transform)){
      transform_result['translate'] = [parseFloat(translate[1]), parseFloat(translate[2])];
    }
    if(scale = /scale\(\s?([0-9]*\.?[0-9]+)(?:\s?.*)\)/.exec(transform)) {
      transform_result['scale'] = parseFloat(scale[1]);
    }
    return transform_result;
  }

  return {
    zoom_in: function() {
      transform.scale = transform.scale + 0.5;
      graph.attr('transform', 'scale(' + transform.scale + ') translate('+transform.translate.join(',')+')');
    },
    zoom_out: function() {
      if(transform.scale - 0.5 > 0){
        transform.scale = transform.scale - 0.5;
      }
      graph.attr('transform', 'scale(' + transform.scale + ') translate('+transform.translate.join(',')+')');
    }
  }
}
$(function() {
  function restart() {
    waiter = window.setInterval(setup, 100);
  }
  //Hacky way to make sure that the svg is loaded
  function setup() {
    clearInterval(waiter);
    try {
      svg = document.getElementById('graph');
      if(svg == undefined) { throw "restart"; }
      SVGView = SvgViewPane(document.getElementById('graph').getSVGDocument());
    } catch(e) {restart() }
  }
  restart();

  // Bind zoom actions
  $('#zin').click(function(e){
    SVGView.zoom_in();
    e.preventDefault();
  });
  $('#zout').click(function(e){
    SVGView.zoom_out();
    e.preventDefault();
  });
});

