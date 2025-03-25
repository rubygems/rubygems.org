import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];
  static classes = [];

  connect() {}

  async accept(e) {
    e.preventDefault();
    const response = await fetch(this.element.dataset.policiesAction, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify({ accept: true }),
    });

    if (response.ok) {
      this.element.remove();
    } else {
      alert(
        "There was an error acknowledging the policies. Please try again.\n\nError: " +
          response.statusText
      );
      console.error(response);
    }
  }
}
