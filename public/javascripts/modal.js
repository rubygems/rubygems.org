$(function() {
  $('#js-sign-in-trigger').click(function(e) {
    if ($('#js-sign-in-modal').hasClass('is-showing')){
      e.preventDefault();
    }
    else {
      e.preventDefault();
      $('#js-sign-in-modal').addClass('is-showing');
      $('body').addClass('has-modal');
    }
  });

  $('.js-sign-up-trigger').click(function(e) {
    if ($('#js-sign-up-modal').hasClass('is-showing')){
      e.preventDefault();
    }
    else {
      e.preventDefault();
      $('#js-sign-up-modal').addClass('is-showing');
      $('body').addClass('has-modal');
    }
  });

  $('#js-sign-in-close').click(function(e) {
    e.preventDefault();
    $('#js-sign-in-modal').removeClass('is-showing');
    $('body').removeClass('has-modal');
  });

  $('#js-sign-up-close').click(function(e) {
    e.preventDefault();
    $('#js-sign-up-modal').removeClass('is-showing');
    $('body').removeClass('has-modal');
  });
});
