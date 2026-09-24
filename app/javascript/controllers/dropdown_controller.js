import { Controller } from "@hotwired/stimulus";

// I tested the stimulus-dropdown component but it has too many deps.
// This mimics the basic stimulus-dropdown api, so we could swap it in later.
export default class extends Controller {
  static targets = ["button", "menu"];

  hide(e) {
    if (
      !this.element.contains(e.target) &&
      !this.menuTarget.classList.contains("hidden")
    ) {
      this.menuTarget.classList.add("hidden");
      this.setExpanded(false);
    }
  }

  toggle(e) {
    e.preventDefault();
    this.menuTarget.classList.toggle("hidden");
    this.setExpanded(!this.menuTarget.classList.contains("hidden"));
  }

  setExpanded(expanded) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", expanded);
    }
  }
}
