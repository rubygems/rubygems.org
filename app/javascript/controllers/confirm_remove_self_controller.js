import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog", "usernameInput", "submitButton"];
  static values = { username: String };

  open() {
    this.usernameInputTarget.value = "";
    this.submitButtonTarget.disabled = true;
    this.dialogTarget.show();
  }

  close() {
    this.dialogTarget.close();
  }

  validate() {
    this.submitButtonTarget.disabled =
      this.usernameInputTarget.value.trim() !== this.usernameValue;
  }
}
