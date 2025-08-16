import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { width: String }

  connect() {
    const el = this.element
    el.style.display = "block"
    el.classList.remove("t-item--hidden")

    // Animate width to the provided value over 700ms
    el.style.transition = "width 700ms"
    // Trigger in next frame to ensure transition applies
    requestAnimationFrame(() => {
      el.style.width = `${this.widthValue}%`
    })
  }
}
