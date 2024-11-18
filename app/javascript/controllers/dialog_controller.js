import Dialog from '@stimulus-components/dialog'

export default class extends Dialog {
  static targets = ["dialog", "button"]

  connect() {
    super.connect()
    this.setAriaExpanded('false')
  }

  open(e) {
    super.open()
    e.preventDefault()
    this.setAriaExpanded('true')
  }

  close(e) {
    super.close()
    e.preventDefault()
    this.setAriaExpanded('false')
  }

  setAriaExpanded(expanded) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', expanded)
    }
  }
}
