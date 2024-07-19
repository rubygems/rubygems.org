import $ from "jquery";

//stats page
$(function() {
  $('.stats__graph__gem__meter').each(function() {
    $(this).animate({ width: $(this).data("bar-width") + '%' }, 700).removeClass('t-item--hidden').css("display", "block");
  });
});
