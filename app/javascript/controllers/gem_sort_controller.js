import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gem-sort"
export default class extends Controller {
  static targets = ["form", "select"]
  connect() {
    this.selectTarget.onchange = () => this.formSubmit();
  }

  formSubmit = () => {
    this.formTarget.submit();
  }
}
