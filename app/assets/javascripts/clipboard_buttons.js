$(function() {
  var clipboard = new Clipboard('.gem__code__icon'),
      copy_tooltip = $('.gem__code__tooltip--copy'),
      copied_tooltip = $('.gem__code__tooltip--copied'),
      copy_buttons = $('.gem__code__icon'),
      gem_install_button = $('#js-gem__code--install');

  function hide_copy_show_copied_tooltips(e) {
    copy_tooltip.removeClass("clipboard-is-hover");
    copied_tooltip.insertAfter(e.trigger);
    copied_tooltip.addClass("clipboard-is-active");
  };

  clipboard.on('success', function(e) {
    hide_copy_show_copied_tooltips(e);
    e.clearSelection();
  });

  clipboard.on('error', function(e) {
    hide_copy_show_copied_tooltips(e);
    copied_tooltip.text("Ctrl-C to Copy");
  });

  copy_buttons.hover(function() {
    copy_tooltip.insertAfter(this);
    copy_tooltip.addClass("clipboard-is-hover");
  });

  copy_buttons.mouseout(function() {
    copy_tooltip.removeClass("clipboard-is-hover");
  });

  copy_buttons.mouseout(function() {
    copied_tooltip.removeClass("clipboard-is-active");
  });
});
