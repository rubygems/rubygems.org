import { Controller } from "@hotwired/stimulus";

// I tested the stimulus-dropdown component but it has too many deps.
// This mimics the basic stimulus-dropdown api, so we could swap it in later.
export default class extends Controller {
  static targets = ["menu"];

  show(e) {
    if (e.pointerType === "mouse") {
      this.menuTarget.classList.remove("hidden");
    }
  }

  hide(e) {
    if (e.type === "pointerleave") {
      if (
        e.pointerType !== "mouse" ||
        this.element.contains(document.activeElement)
      )
        return;
    } else if (e.type === "focusout") {
      if (
        this.element.contains(e.relatedTarget) ||
        this.element.matches(":hover")
      )
        return;
    } else if (this.element.contains(e.target)) {
      return;
    }

    this.menuTarget.classList.add("hidden");
  }

  toggle(e) {
    e.preventDefault();
    this.menuTarget.classList.toggle("hidden");
  }
}
