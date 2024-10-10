import Reveal from '@stimulus-components/reveal'

export default class extends Reveal {
  static targets = ["item", "toggle", "button"]
  static classes = ["hidden", "toggle"]

  connect() {
    super.connect()
    if (this.hasButtonTarget) {
      this.buttonTarget.ariaExpanded = false
    }
  }
  toggle() {
    super.toggle()
    if (this.hasButtonTarget) {
      this.buttonTarget.ariaExpanded = this.buttonTarget.ariaExpanded !== "true"
    }
    if (this.hasToggleTarget && this.hasToggleClass) {
      this.toggleClasses.forEach((className) => {
        this.toggleTarget.classList.toggle(className)
      })
    }
  }

  show() {
    super.show()
    if (this.hasButtonTarget) {
      this.buttonTarget.ariaExpanded = true
    }
    if (this.hasToggleTarget && this.hasToggleClass) {
      this.toggleTarget.classList.add(...this.toggleClasses)
    }
  }

  hide() {
    super.hide()
    if (this.hasToggleTarget) {
      this.buttonTarget.ariaExpanded = false
    }
    if (this.hasToggleTarget && this.hasToggleClass) {
      this.toggleTarget.classList.add(...this.toggleClasses)
    }
  }
}
