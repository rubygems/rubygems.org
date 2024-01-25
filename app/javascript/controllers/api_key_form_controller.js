import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gemCheckbox", "gemSelector"]

  connect() {
    this.toggleGemSelector();
  }

  gemCheckboxTargetConnected(el) {
    el.addEventListener("click", () => this.toggleGemSelector() );
  }

  toggleGemSelector() {
    var isApplicableGemSelected = this.gemCheckboxTargets.find((target) => target.checked);
    if (isApplicableGemSelected) {
      this.gemSelectorTarget.disabled = false;
      this.removeHiddenRubygemField();
    } else {
      this.gemSelectorTarget.value = "";
      this.gemSelectorTarget.disable = true;
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

