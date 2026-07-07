import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["displayname", "organizationhandle", "submit"];

  connect() {
    this.validate();
  }

  updateDisplayname(e) {
    this.updateDisplaynameWith(e.currentTarget.value);
    this.validate();
  }

  updateHandle(e) {
    this.updateHandleWith(e.currentTarget.value);
    this.validate();
  }

  validate() {
    this.submitTarget.disabled = !this.element.checkValidity();
  }

  updateHandleWith(value) {
    // Slugify into a URL-safe handle: lowercase, spaces/underscores to dashes,
    // drop anything else, and collapse repeated dashes.
    this.organizationhandleTarget.value = value
      .toLowerCase()
      .replace(/[\s_]+/g, "-")
      .replace(/[^a-z0-9-]/g, "")
      .replace(/-+/g, "-");
  }
}
