/* A controller that, when loaded, causes the page to refresh periodically */

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scroll", "scrollLeft"]

  scrollLeftTargetConnected() {
    this.element.scrollLeft = this.scrollLeftTarget.offsetLeft + this.scrollLeftTarget.offsetWidth / 2 - this.element.offsetWidth / 2
  }

  scrollTargetConnected() {
    this.scrollTarget.scrollIntoView({ behavior: "smooth" })
  }

  scroll(e) {
    e.currentTarget.scrollIntoView({ behavior: "smooth" })
  }
}
