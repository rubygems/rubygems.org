$(document).ready(function() {
  $('#version_for_stats').change(function() {
    window.location.href = $(this).val();
  });

  if (window.location.hash != '#tips') { $('#search-tips').hide(); }
  $('#search-tips-toggle').click(function(e) {
    e.preventDefault();
    var o = $('#search-tips');
    if ( o.is(':visible') ) {
      o.hide('fast');
      window.location.hash = '';
    } else {
      o.show('fast');
      window.location.hash = '#tips';
    }
  });
});
