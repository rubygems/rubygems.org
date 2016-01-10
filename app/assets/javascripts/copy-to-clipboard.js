$(function() {
  var copyToClipboard = new Clipboard('.gem__code__clipboard');

  function showNotification(event) {
    var copyButton = $(event.trigger);
    copyButton.addClass('clipboard-is-active');
    setTimeout(function() {
      copyButton.removeClass('clipboard-is-active');
    }, 1000);
  }

  copyToClipboard.on('success', function(event) {
    showNotification(event);
  });

  copyToClipboard.on('error', function(event) {
    $('.gem__code__tooltip--copied').text('ctrl/cmd + c');
    showNotification(event);
  });
});
