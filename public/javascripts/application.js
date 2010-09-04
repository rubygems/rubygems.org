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

  if ($('.count').length > 0) {
    setInterval(function() {
      $.getJSON('/api/v1/downloads.json', function(data) {
        $('.count strong')
          .text(number_with_delimiter(data['total']) + ' downloads');
      });
    }, 5000);
  }

  if ($('.downloads.counter').length > 0) {
    setInterval(function() {
      $.getJSON($('.downloads.counter').attr('data-href'), function(data) {
        $('.downloads.counter strong:first')
          .text(number_with_delimiter(data['total_downloads']));
        $('.downloads.counter strong:last')
          .text(number_with_delimiter(data['latest_version_downloads']));
      });
    }, 5000);
  }
});

// http://kevinvaldek.com/number-with-delimiter-in-javascript
function number_with_delimiter(number, delimiter) {
  number = number + '', delimiter = delimiter || ',';
  var split = number.split('.');
  split[0] = split[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1' + delimiter);
  return split.join('.');
};
