import Dialog from '@stimulus-components/dialog'

export default class extends Dialog {
  static targets = ["dialog", "button"]

  connect() {
    super.connect()
    this.setAriaExpanded('false')
  }

  open() {
    super.open()
    this.setAriaExpanded('true')
  }

  close() {
    super.close()
    this.setAriaExpanded('false')
  }

  setAriaExpanded(expanded) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', expanded)
    }
  }
}
