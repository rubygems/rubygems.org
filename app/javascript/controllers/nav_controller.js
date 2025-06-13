import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "collapse", // targets that receive expanded class when mobile nav shows
    "header", // target on which clicks don't hide mobile nav
    "logo",
    "search",
  ]
  static classes = ["expanded"]

  connect(){this.mousedown = false}

  toggle(e) {
    e.preventDefault();
    if (this.collapseTarget.classList.contains(this.expandedClass)) {
      this.leave()
      this.logoTarget.focus();
    } else {
      this.enter()
    }
  }

  // This event is used to open the menu when user presses "TAB" and focuses on the burger menu
  focus(event) {
    // Ignore click events on the burger menu, we are only interested in tab events
    if (this.mousedown){
      this.mousedown = false
      return;
    }
    // Open the menu
    this.enter();
    // Wait 50ms before focusing on the search input - necessary for Firefox mobile
    setTimeout(() => {
      this.hasSearchTarget && this.searchTarget.focus();
    }, 50);
  }

  // Register if last event was a mousedown
  mouseDown(e){
    this.mousedown = true
  }

  hide(e) { !this.headerTarget.contains(e.target) && this.leave() }
  leave() { this.collapseTargets.forEach(el => el.classList.remove(this.expandedClass)) }
  enter() { this.collapseTargets.forEach(el => el.classList.add(this.expandedClass)) }
}
