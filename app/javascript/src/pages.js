import $ from "jquery";

//gem page
$(function() {
  $('.gem__users__mfa-text.mfa-warn').on('click', function() {
    $('.gem__users__mfa-text.mfa-warn').toggleClass('t-item--hidden');

    $owners = $('.gem__users__mfa-disabled');
    $owners.toggleClass('t-item--hidden');
  });
});
