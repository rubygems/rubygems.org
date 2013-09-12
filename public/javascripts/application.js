$(document).ready(function() {
  $('#version_for_stats').change(function() {
    window.location.href = $(this).val();
  });

  $('#dep_check').change(function(){
    $(this).parents('.depTree').toggleClass('runtime');
  });
});
