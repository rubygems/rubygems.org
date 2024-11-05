import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter", "checkbox"]

  connect() {
    this.update()
  }

  checkboxTargetConnected(el) {
    el.addEventListener("change", this.update.bind(this))
    el.addEventListener("input", this.update.bind(this)) // input emitted by checkbox-select-all controller
  }

  checkboxTargetdisconnected(el) {
    el.removeEventListener("change", this.update.bind(this))
    el.removeEventListener("input", this.update.bind(this))
  }

  update() {
    const count = this.checkboxTargets.filter(el => el.checked).length
    this.counterTarget.textContent = count
  }
}
