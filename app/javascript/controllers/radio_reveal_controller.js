import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "radio",
    "item",
  ]

  connect() {
    this.update()
  }

  update() {
    this.itemTargets.forEach(item => {
      item.classList.add("hidden")
    })

    this.radioTargets.forEach(radio => {
      if (radio.checked) {
        const item = this.itemTargets.find(item => item.dataset.name == radio.value)
        item.classList.remove("hidden")
      }
    })
  }
}
