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

  /*
  if ($('.count').length > 0) {
    setInterval(function() {
      $.getJSON('/api/v1/downloads.json', function(data) {
        $('.count strong')
          .text(number_with_delimiter(data['total']) + ' downloads');
      });
    }, 5000);
  }
  */

  $('#version_for_stats').change(function() {
    window.location.href = $(this).val();
  });

  /*
  if ($('.downloads.counter').length > 0) {
    var options   = { color : $('.downloads').css('color') };
    var highlight = '#A70E0E';

    setInterval(function() {
      $.getJSON($('.downloads.counter').attr('data-href'), function(data) {
        var total   = $('.downloads.counter strong:first');
        var version = $('.downloads.counter strong:last');

        var previous_total_downloads   = parseInt(total.text().replace(/,/g, ""), 10);
        var previous_version_downloads = parseInt(version.text().replace(/,/g, ""), 10);

        if (previous_total_downloads != data['total_downloads']) {
          total
            .text(number_with_delimiter(data['total_downloads']))
            .css('color', highlight)
            .animate(options, 1500).dequeue();
        }

        if (previous_version_downloads != data['version_downloads']) {
          version
            .text(number_with_delimiter(data['version_downloads']))
            .css('color', highlight)
            .animate(options, 1500).dequeue();
        }
      });
    }, 5000);
  }
  */
});

// http://kevinvaldek.com/number-with-delimiter-in-javascript
function number_with_delimiter(number, delimiter) {
  number = number + '', delimiter = delimiter || ',';
  var split = number.split('.');
  split[0] = split[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1' + delimiter);
  return split.join('.');
};
