$(document).ready(function() {
  if (window.location.href.search(/query=/) == -1) {
    $('#query').one('click, focus', function() {
      $(this).val('');
    });
  }

  $('#version_for_stats').change(function() {
    window.location.href = $(this).val();
  });

});
