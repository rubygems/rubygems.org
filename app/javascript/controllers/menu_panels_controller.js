import { Controller } from "@hotwired/stimulus";

// Switches the mobile navigation menu between its main panel and a sub-panel.
export default class extends Controller {
  static targets = ["main", "sub", "opener", "back"];

  showSub() {
    this.mainTarget.hidden = true;
    this.subTarget.hidden = false;
    this.openerTarget.setAttribute("aria-expanded", "true");
    this.backTarget.focus();
  }

  showMain({ type } = {}) {
    if (this.mainTarget.hidden === false) return;

    this.subTarget.hidden = true;
    this.mainTarget.hidden = false;
    this.openerTarget.setAttribute("aria-expanded", "false");
    if (type !== "close") this.openerTarget.focus();
  }
}
