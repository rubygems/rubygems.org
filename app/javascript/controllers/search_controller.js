import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "query", "attribute" ]

  input(e) {
    this.queryTarget.value = this.attributeTargets.map(field =>
      field.value.length > 0 && field.checkValidity() ? `${field.name}: ${field.value}` : ''
    ).join(' ')
  }

  submit() {
    this.queryTarget.form.submit()
  }
}
