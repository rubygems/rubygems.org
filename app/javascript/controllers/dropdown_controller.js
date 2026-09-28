import { Controller } from "@hotwired/stimulus";

// I tested the stimulus-dropdown component but it has too many deps.
// This mimics the basic stimulus-dropdown api, so we could swap it in later.
export default class extends Controller {
  static targets = ["button", "menu"];

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
        e.relatedTarget === null ||
        this.element.contains(e.relatedTarget) ||
        (!this.hasButtonTarget && this.element.matches(":hover"))
      )
        return;
    } else if (this.element.contains(e.target)) {
      return;
    }

    this.menuTarget.classList.add("hidden");
    this.setExpanded(false);
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
