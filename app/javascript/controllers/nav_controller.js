import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "collapse", // targets that receive expanded class when mobile nav shows
    "header", // target on which clicks don't hide mobile nav
    "logo",
    "search",
  ]
  static classes = ["expanded"]

  connect() { this.skipSandwichIcon = true }

  toggle(e) {
    e.preventDefault();
    if (this.collapseTarget.classList.contains(this.expandedClass)) {
      this.leave()
      this.logoTarget.focus();
    } else {
      this.enter()
    }
  }

  focus() {
    if (this.skipSandwichIcon) { // skip sandwich icon when you tab from "gem" icon
      this.enter();
      this.hasSearchTarget && this.searchTarget.focus();
      this.skipSandwichIcon = false;
    } else {
      this.leave();
      this.logoTarget.focus();
      this.skipSandwichIcon = true;
    }
  }

  hide(e) { !this.headerTarget.contains(e.target) && this.leave() }
  leave() { this.collapseTargets.forEach(el => el.classList.remove(this.expandedClass)) }
  enter() { this.collapseTargets.forEach(el => el.classList.add(this.expandedClass)) }
}
