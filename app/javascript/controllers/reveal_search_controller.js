import Reveal from "controllers/reveal_controller";

export default class extends Reveal {
  static targets = ["item", "toggle", "button", "input"];

  focus(event) {
    if (
      event.key !== "/" ||
      event.altKey ||
      event.ctrlKey ||
      event.metaKey ||
      event.shiftKey ||
      event.target.closest(
        "input, textarea, select, [contenteditable]:not([contenteditable='false'])",
      )
    ) {
      return;
    }

    event.preventDefault();
    this.show();
    this.inputTarget.focus();
  }

  toggle() {
    super.toggle();
    if (!this.itemTarget.classList.contains("hidden")) {
      this.inputTarget.focus(); // Auto focus the input when revealed
    }
  }

  open() {
    super.open();
    this.inputTarget.focus();
  }
}
