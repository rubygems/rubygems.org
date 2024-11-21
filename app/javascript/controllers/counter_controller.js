import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter", "checked"]

  connect() {
    this.update()
  }

  checkedTargetConnected(el) {
    el.addEventListener("change", this.update.bind(this))
    el.addEventListener("input", this.update.bind(this)) // input emitted by checkbox-select-all controller
  }

  checkedTargetdisconnected(el) {
    el.removeEventListener("change", this.update.bind(this))
    el.removeEventListener("input", this.update.bind(this))
  }

  update() {
    const count = this.checkedTargets.filter(el => el.checked).length
    this.counterTarget.textContent = count
  }
}
