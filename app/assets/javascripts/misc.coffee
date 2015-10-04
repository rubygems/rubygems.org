$(document).ready ->
  $('#version_for_stats').change ->
    window.location.href = $(this).val()
