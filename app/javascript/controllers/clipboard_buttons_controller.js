import { Controller } from "@hotwired/stimulus"
import ClipboardJS from "clipboard"

export default class extends Controller {
  static targets = [ "copyTooltip copiedTooltip button" ]

  connect() {
    this.copyTooltip = $(this.copyTooltipTarget);
    this.copiedTooltip = $(this.copiedTooltipTarget);
  }

  buttonTargetConnected(el) {
    console.log("buttonTargetConnected", el);
    const controller = this;

    el.addEventListener('hover', function() {
      controller.copyTooltip.insertAfter(this);
      controller.copyTooltip.addClass("clipboard-is-hover");
    });

    el.addEventListener('mouseout', function() {
      controller.copyTooltip.removeClass("clipboard-is-hover");
      controller.copiedTooltip.removeClass("clipboard-is-active");
    });

    const clipboard = new ClipboardJS(el);

    clipboard.on('success', (e) => {
      this.hideCopyShowCopiedTooltips(e);
      e.clearSelection();
    });

    clipboard.on('error', (e) => {
      this.hideCopyShowCopiedTooltips(e);
      this.copiedTooltip.text("Ctrl-C to Copy");
    });
  }

  hideCopyShowCopiedTooltips(e) {
    this.copyTooltip.removeClass("clipboard-is-hover");
    this.copiedTooltip.insertAfter(e.trigger);
    this.copiedTooltip.addClass("clipboard-is-active");
  }
}