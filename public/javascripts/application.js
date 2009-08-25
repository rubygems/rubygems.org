$(document).ready(function() {
  divs = "#flash_success, #flash_notice, #flash_error"
  $(divs).slideDown(function() {
    timeout = setTimeout(function() {
    $(divs).slideUp();
    }, 10000);
  });

  if(window.location.href.search(/query=/) == -1) {
    $("#query").click(function() {
      $(this).val("");
      $(this).unbind("click");
    });
  }
});
