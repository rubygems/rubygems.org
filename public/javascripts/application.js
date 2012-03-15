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
