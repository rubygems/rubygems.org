import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "dropdown" ]

  buttonTargetConnected(el) {
    el.addEventListener("click", (e) => {
      e.preventDefault();
      this.dropdownTarget.classList.toggle('is-expanded');
    });

    document.addEventListener("click", (e) => {
      if (!this.element.contains(e.target)) {
        this.dropdownTarget.classList.remove('is-expanded');
      }
    });
  }
}