import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "gemSelector", "orgSelector"];

  initialize() {
    this.hiddenFields = {};
  }

  connect() {
    this.toggleSelectors();
  }

  checkboxTargetConnected(el) {
    el.addEventListener("change", () => this.toggleSelectors());
  }

  gemSelectorTargetConnected(el) {
    el.addEventListener("change", () => {
      if (el.value && this.hasOrgSelectorTarget) {
        this.orgSelectorTarget.value = "";
      }
    });
  }

  orgSelectorTargetConnected(el) {
    el.addEventListener("change", () => {
      if (el.value && this.hasGemSelectorTarget) {
        this.gemSelectorTarget.value = "";
      }
    });
  }

  toggleSelectors() {
    const selected = this.checkboxTargets.find((target) => target.checked);

    if (this.hasGemSelectorTarget) {
      this.toggleSelector(
        "api_key[rubygem_id]",
        this.gemSelectorTarget,
        selected,
      );
    }
    if (this.hasOrgSelectorTarget) {
      this.toggleSelector(
        "api_key[organization_id]",
        this.orgSelectorTarget,
        selected,
      );
    }
  }

  toggleSelector(fieldName, selectorTarget, enabled) {
    if (enabled) {
      selectorTarget.disabled = false;
      this.removeHiddenField(fieldName);
    } else {
      selectorTarget.value = "";
      selectorTarget.disabled = true;
      this.addHiddenField(fieldName);
    }
  }

  addHiddenField(fieldName) {
    if (this.hiddenFields[fieldName]) {
      return;
    }

    this.hiddenFields[fieldName] = document.createElement("input");
    this.hiddenFields[fieldName].type = "hidden";
    this.hiddenFields[fieldName].name = fieldName;
    this.hiddenFields[fieldName].value = "";
    this.element.appendChild(this.hiddenFields[fieldName]);
  }

  removeHiddenField(fieldName) {
    if (this.hiddenFields[fieldName]) {
      this.hiddenFields[fieldName].remove();
      this.hiddenFields[fieldName] = null;
    }
  }
}
