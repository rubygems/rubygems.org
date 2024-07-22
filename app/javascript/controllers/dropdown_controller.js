import { Controller } from "@hotwired/stimulus"

// I tested the stimulus-dropdown component but it has too many deps.
// This mimics the basic stimulus-dropdown api, so we could swap it in later.
export default class extends Controller {
  static targets = ["menu"]

  hide(e) {
    !this.element.contains(e.target) &&
      !this.menuTarget.classList.contains("hidden") &&
      this.menuTarget.classList.add('hidden');
  }

  toggle(e) {
    e.preventDefault();
    this.menuTarget.classList.toggle('hidden');
  }
}
