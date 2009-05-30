$(document).ready(function() {
  divs = "#flash_success, #flash_notice, #flash_error"
  $(divs).slideDown(function() {
    timeout = setTimeout(function() {
    $(divs).slideUp();
    }, 10000);
  });
});
