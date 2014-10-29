// HTML5 Meter Shim
// Adapted from:
// https://github.com/xjamundx/HTML5-Meter-Shim
// by Jamund Feguson (@xjamundx)
// and Rob Middleton (@rob__ot)

// create shim
jQuery.fn.meterShim = function() {

  return $(this).each(function() {

    var $meter = $(this);
    var min = parseFloat($meter.attr('min'), 10) || 0; // default as per HTML5 spec
    var max = parseFloat($meter.attr('max'), 10) || 1; // default as per HTML5 spec
    var high = parseFloat($meter.attr('high'), 10);
    var low = parseFloat($meter.attr('low'), 10);
    var optimum = parseFloat($meter.attr('optimum'), 10);
    var value = $meter.attr('value') != null ? parseFloat($meter.attr('value'), 10) : $meter.text();
    var title = $meter.attr('title') != null ? $meter.attr('title') : value;

    // get all the classes on the meter so we can add them to our new div
    var meterClasses = $meter.attr('class').split(/\s+/);
    var width = 0;
    var height = 0;
    var $it = $('<div>').addClass('meter');

    // add all of the meter classes to $it
    for (var i = 0; i < meterClasses.length; i += 1) {
      $it.addClass(meterClasses[i]);
    }

    // replace <meter> with a <div class="meter">
    $meter.replaceWith($it)
    $meter = $it

    // here is the template for our indicator
    var $indicator = $('<div>').addClass('stats__graph__gem__meter-polyfill');
    var $div;
    var $child;

    // delete any text
    $meter.text("")

    /*
      The following inequalities must hold, as applicable:
      * minimum ≤ value ≤ maximum
      * minimum ≤ low ≤ maximum (if low is specified)
      * minimum ≤ high ≤ maximum (if high is specified)
      * minimum ≤ optimum ≤ maximum (if optimum is specified)
      * low ≤ high (if both low and high are specified)
    */

   function adjustWidth() {

     if (value < min) {
       value = min;
     }
     if (value > max) {
       value = max;
     }
     if (low != null && low < min) {
       low = min;
     }
     if (high != null && high > max) {
       high = max;
     }

     width = value/max*100;
     width = Math.ceil(width)

     return String(width) + '%';
   }

    // get or create our indicator element
    $child = $meter.children('.indicator:first-of-type')
    $div = $child.length ? $child : $indicator.clone();
    $div.css('width', adjustWidth());

    if (high && value >= high) {
      $meter.addClass('meterValueTooHigh');
    } else if (low && value <= low) {
      $meter.addClass('meterValueTooLow');
    } else {
      $meter.removeClass('meterValueTooHigh');
      $meter.removeClass('meterValueTooLow');
    }

    $meter.toggleClass('meterIsMaxed', value >= max);
    $meter.attr('title', title);

    if (!$child.length) {
      $meter.append($div);
    }
  })
}

$(document).ready(function() {
  var supportsMeter = 'value' in document.createElement('meter');

    // don't waste time if you don't need to
    if (!supportsMeter && $('.stats').length > 0){
      $('meter').meterShim();
    }
});
