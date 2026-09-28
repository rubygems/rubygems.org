import { Controller } from "@hotwired/stimulus";

// I tested the stimulus-dropdown component but it has too many deps.
// This mimics the basic stimulus-dropdown api, so we could swap it in later.
export default class extends Controller {
  static targets = ["button", "menu"];

  hide(e) {
    // Clicks report the clicked element; focusout reports where focus moved to.
    const destination = e.type === "focusout" ? e.relatedTarget : e.target;
    if (e.type === "focusout" && destination === null) return;

    if (
      !this.element.contains(destination) &&
      !this.menuTarget.classList.contains("hidden")
    ) {
      this.menuTarget.classList.add("hidden");
      this.setExpanded(false);
    }
  }

  close(e) {
    if (this.menuTarget.classList.contains("hidden")) return;

    e.preventDefault();
    this.menuTarget.classList.add("hidden");
    this.setExpanded(false);
    if (this.hasButtonTarget) this.buttonTarget.focus();
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
