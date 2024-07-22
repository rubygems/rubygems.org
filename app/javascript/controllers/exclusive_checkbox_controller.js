import { Controller } from "@hotwired/stimulus"

// Supports one exclusive target, but many inclusive targets
export default class extends Controller {
  static targets = ["inclusive", "exclusive"]

  connect() {
    // Unselect all inclusive targets if the exclusive target is selected on load
    this.updateExclusive()
  }

  exclusiveTargetConnected(el) {
    el.addEventListener("change", () => this.updateExclusive())
  }

  inclusiveTargetConnected(el) {
    el.addEventListener("change", (e) => {
      if (e.currentTarget.checked) { this.uncheck(this.exclusiveTarget) }
    })
  }

  updateExclusive() {
    if (this.exclusiveTarget.checked) { 
      this.inclusiveTargets.forEach(this.uncheck)
    }
  }

  uncheck(checkbox) {
    if (checkbox.checked) {
      checkbox.checked = false
      checkbox.dispatchEvent(new Event("change"))
    }
  }
}

