import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selector"]

  connect() {
    this.toggleSelector()
  }

  checkboxTargetConnected(el) {
    el.addEventListener("change", () => this.toggleSelector())
  }

  toggleSelector() {
    const selected = this.checkboxTargets.find((target) => target.checked)

    if (selected) {
      this.selectorTarget.disabled = false;
      this.removeHiddenRubygemField();
    } else {
      this.selectorTarget.value = "";
      this.selectorTarget.disabled = true;
      this.addHiddenRubygemField();
    }
  }

  addHiddenRubygemField() {
    if (this.hiddenField) { return }
    this.hiddenField = document.createElement("input");
    this.hiddenField.type = "hidden";
    this.hiddenField.name = "api_key[rubygem_id]";
    this.hiddenField.value = "";
    this.element.appendChild(this.hiddenField);
  }

  removeHiddenRubygemField() {
    if (this.hiddenField) {
      this.hiddenField.remove();
      this.hiddenField = null;
    }
  }
}

