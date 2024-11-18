import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    confirm: { type: String, default: "Leave without copying recovery codes?" }
  }

  connect() {
    this.copied = false;
    window.addEventListener("beforeunload", this.popUp);
  }

  popUp(e) {
    e.preventDefault();
    e.returnValue = "";
  }

  copy() {
    if (!this.copied) {
      this.copied = true;
      window.removeEventListener("beforeunload", this.popUp);
    }
  }

  submit(e) {
    e.preventDefault();

    if (!this.element.checkValidity()) {
      this.element.reportValidity();
      return;
    }

    if (this.copied || confirm(this.confirmValue)) {
      window.removeEventListener("beforeunload", this.popUp);
      // Don't include the form data in the URL.
      window.location.href = this.element.action;
    }
  }
}
