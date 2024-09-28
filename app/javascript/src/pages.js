import $ from "jquery";

//stats page
$(function() {
  $('.stats__graph__gem__meter').each(function() {
    $(this).animate({ width: $(this).data("bar-width") + '%' }, 700).removeClass('t-item--hidden').css("display", "block");
  });
});

//gem page
$(function() {
  $('.gem__users__mfa-text.mfa-warn').on('click', function() {
    $('.gem__users__mfa-text.mfa-warn').toggleClass('t-item--hidden');

    $owners = $('.gem__users__mfa-disabled');
    $owners.toggleClass('t-item--hidden');
  });
});
