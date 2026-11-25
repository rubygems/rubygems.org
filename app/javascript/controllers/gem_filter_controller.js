import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = ["input", "clear", "sort", "form", "submit"];

  connect() {
    if (!this.hasInputTarget) return;

    this.inputTarget.value =
      new URL(window.location.href).searchParams.get("gem_filter") || "";
    this.submitTarget.hidden = true;
    this.updateSort();
  }

  disconnect() {
    clearTimeout(this.timer);
  }

  submit(event) {
    event.preventDefault();
    clearTimeout(this.timer);
    const url = new URL(this.formTarget.action);
    url.search = new URLSearchParams(new FormData(this.formTarget)).toString();
    // Keep filtering and pagination on the same frame navigation path.
    // Turbo-managed form submissions cancel separately from frame links, so
    // an older page response could overwrite newer filtered results.
    Turbo.visit(url.href, {
      frame: this.formTarget.dataset.turboFrame,
      action: "advance",
    });
  }

  filter() {
    this.updateSort();
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.formTarget.requestSubmit(), 250);
  }

  updateSort() {
    const query = this.inputTarget.value.trim();
    this.clearTarget.hidden = this.inputTarget.value.length === 0;

    // Sorting still navigates through GemSortable; carry the filter with
    // it without changing global search or the sort cookie.
    this.sortTarget.querySelectorAll("a").forEach((link) => {
      const url = new URL(link.href);
      if (query) url.searchParams.set("gem_filter", query);
      else url.searchParams.delete("gem_filter");
      link.href = url.toString();
    });
    const form = this.sortTarget.querySelector("form");
    let input = form.querySelector('input[name="gem_filter"]');
    if (!input) {
      input = document.createElement("input");
      input.type = "hidden";
      input.name = "gem_filter";
      form.append(input);
    }
    input.value = query;
    input.disabled = !query;
  }

  clear(event) {
    event.preventDefault();
    this.inputTarget.value = "";
    this.filter();
    this.inputTarget.focus();
  }
}
