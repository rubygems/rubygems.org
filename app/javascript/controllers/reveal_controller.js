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
      this.setAriaExpanded(this.buttonTarget.ariaExpanded === "true" ? "false" : "true")
    }
    if (this.hasToggleTarget && this.hasToggleClass) {
      this.toggleClasses.forEach((className) => {
        this.toggleTarget.classList.toggle(className)
      })
    }
  }

  show() {
    super.show()
    if (this.hasToggleTarget && this.hasToggleClass) {
      this.toggleTarget.classList.add(...this.toggleClasses)
    }
  }

  hide() {
    super.hide()
    this.setAriaExpanded('false')
    if (this.hasToggleTarget && this.hasToggleClass) {
      this.toggleTarget.classList.add(...this.toggleClasses)
    }
  }

  setAriaExpanded(expanded) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', expanded)
    }
  }
}
