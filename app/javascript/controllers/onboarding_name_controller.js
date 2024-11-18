import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "radio",
    "gemname",
    "username",
    "reveal",
    "displayname",
    "submit",
  ]

  connect() {
    this.submitTarget.disabled = true
    this.radioTargets.forEach((radio) => {
      if (radio.checked) {
        this[radio.value+"name"]()
      }
    })
  }

  gemnameField() {
    return this.gemnameTarget.querySelector("select")
  }

  usernameField() {
    return this.usernameTarget.querySelector("input")
  }

  gemname() {
    this.usernameTarget.classList.add("hidden")

    this.gemnameField().disabled = false
    this.gemnameTarget.classList.remove("hidden")
    this.revealTarget.classList.remove("hidden")

    const inputElement = this.gemnameField()
    inputElement.focus()
    this.updateDisplaynameWith(inputElement.value)
    if (inputElement.value === "") {
      this.submitTarget.disabled = true
    }
    this.validate()
  }

  username() {
    this.gemnameTarget.classList.add("hidden")
    this.gemnameField().disabled = true

    this.usernameTarget.classList.remove("hidden")
    this.revealTarget.classList.remove("hidden")

    this.updateDisplaynameWith(this.usernameField().value)
    this.validate()
  }

  validate() {
    if (this.element.checkValidity()) {
      this.submitTarget.disabled = false
    } else {
      this.submitTarget.disabled = true
    }
  }

  updateDisplayname(e) {
    this.updateDisplaynameWith(e.currentTarget.value)
    this.validate()
  }

  updateDisplaynameWith(value) {
    // Replace dashes and underscores with spaces. Capitalize the first letter of each word.
    this.displaynameTarget.value = value.replace(/[-_]/g, " ").replace(/\b\w/g, (char) => char.toUpperCase())
  }
}
