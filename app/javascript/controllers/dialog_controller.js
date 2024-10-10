import Dialog from '@stimulus-components/dialog'

export default class extends Dialog {
  static targets = ["dialog", "button"]

  connect() {
    super.connect()
  }

  open() {
    super.open()
    if (this.hasButtonTarget) {
      this.buttonTarget.ariaExpanded = true
    }
  }

  close() {
    if (this.hasButtonTarget) {
      this.buttonTarget.ariaExpanded = false
    }
    super.close()
  }
}
