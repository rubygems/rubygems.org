import Dialog from "@stimulus-components/dialog";

export default class extends Dialog {
  static targets = ["dialog", "button"];

  initialize() {
    super.initialize();
    this.handleDialogClose = this.handleDialogClose.bind(this);
  }

  connect() {
    super.connect();
    this.dialogTarget.addEventListener("close", this.handleDialogClose);
    this.setAriaExpanded("false");
  }

  disconnect() {
    this.dialogTarget.removeEventListener("close", this.handleDialogClose);
    super.disconnect();
  }

  open(e) {
    super.open();
    e.preventDefault();
    this.setAriaExpanded("true");
  }

  close(e) {
    super.close();
    e.preventDefault();
    this.setAriaExpanded("false");
  }

  handleDialogClose() {
    this.setAriaExpanded("false");
  }

  setAriaExpanded(expanded) {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", expanded);
    }
  }
}
