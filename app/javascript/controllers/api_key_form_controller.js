import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "exclusiveCheckbox", "gemSelector"]

  connect() {
    this.toggleGemSelector();
  }

  checkboxTargetConnected(el) {
    el.addEventListener("change", () => {
      if (el.checked) { this.exclusiveCheckboxTarget.checked = false }
      if (el.dataset.gemscope) { this.toggleGemSelector(); }
    })
  }

  exclusiveCheckboxTargetConnected(el) {
    el.addEventListener("change", () => {
      if (el.checked) { this.checkboxTargets.forEach((checkbox) => checkbox.checked = false) }
      this.toggleGemSelector();
    });
  }

  toggleGemSelector() {
    // what type is checkboxTargets?
    var selected = this.checkboxTargets.find(function(target) {
      return target.dataset.gemscope && target.checked
    })

    if (selected) {
      this.gemSelectorTarget.disabled = false;
      this.removeHiddenRubygemField();
    } else {
      this.gemSelectorTarget.value = "";
      this.gemSelectorTarget.disabled = true;
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

