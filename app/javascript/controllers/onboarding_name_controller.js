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
    // Slugify into a URL-safe handle: lowercase, spaces/dashes to underscores,
    // drop anything else, collapse repeated underscores, and trim the leading
    // and trailing ones (the handle must start with a letter).
    this.organizationhandleTarget.value = value
      .toLowerCase()
      .replace(/[\s-]+/g, "_")
      .replace(/[^a-z0-9_]/g, "")
      .replace(/_+/g, "_")
      .replace(/^_+|_+$/g, "");
  }
}
