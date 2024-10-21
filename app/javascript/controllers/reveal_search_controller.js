import Reveal from 'controllers/reveal_controller'

export default class extends Reveal {
  static targets = ["item", "toggle", "button", "input"]

  // There's nothing here because this is just a copy of the reveal controller
  // with a different name. This saves us from a name conflict in the header.
  toggle() {
    super.toggle()
    if (!this.itemTarget.classList.contains("hidden")) {
      this.inputTarget.focus()  // Auto focus the input when revealed
    }
  }

  open() {
    super.open()
    this.inputTarget.focus()
  }
}
