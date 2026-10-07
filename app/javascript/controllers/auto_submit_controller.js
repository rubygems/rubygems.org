import { Controller } from "@hotwired/stimulus";

// Submits the form as soon as one of its controls changes,
// e.g. a search filter or sort select.
export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }
}
