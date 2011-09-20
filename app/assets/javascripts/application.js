// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require_tree .

$(document).ready(function() {
  if (window.location.href.search(/query=/) == -1) {
    $('#query').one('click, focus', function() {
      $(this).val('');
    });
  }

  $(document).bind('keyup', function(event) {
    if ($(event.target).is(':input')) {
      return;
    }

    if (event.which == 83) {
      $('#query').focus();
    }
  });

  $('#version_for_stats').change(function() {
    window.location.href = $(this).val();
  });
});

// http://kevinvaldek.com/number-with-delimiter-in-javascript
function number_with_delimiter(number, delimiter) {
  number = number + '', delimiter = delimiter || ',';
  var split = number.split('.');
  split[0] = split[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1' + delimiter);
  return split.join('.');
};
