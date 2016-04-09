$(function() {
  var clipboard = new Clipboard('.gem__code__icon');
  var copyTooltip = $('.gem__code__tooltip--copy');
  var copiedTooltip = $('.gem__code__tooltip--copied');
  var copyButtons = $('.gem__code__icon');

  function hideCopyShowCopiedTooltips(e) {
    copyTooltip.removeClass("clipboard-is-hover");
    copiedTooltip.insertAfter(e.trigger);
    copiedTooltip.addClass("clipboard-is-active");
  };

  clipboard.on('success', function(e) {
    hideCopyShowCopiedTooltips(e);
    e.clearSelection();
  });

  clipboard.on('error', function(e) {
    hideCopyShowCopiedTooltips(e);
    copiedTooltip.text("Ctrl-C to Copy");
  });

  copyButtons.hover(function() {
    copyTooltip.insertAfter(this);
    copyTooltip.addClass("clipboard-is-hover");
  });

  copyButtons.mouseout(function() {
    copyTooltip.removeClass("clipboard-is-hover");
  });

  copyButtons.mouseout(function() {
    copiedTooltip.removeClass("clipboard-is-active");
  });
});
