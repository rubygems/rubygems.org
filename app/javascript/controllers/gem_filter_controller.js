import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = [
    "controls",
    "input",
    "item",
    "status",
    "empty",
    "clear",
    "sort",
    "form",
    "submit",
  ];

  connect() {
    if (!this.hasInputTarget) return;

    this.inputTarget.value =
      new URL(window.location.href).searchParams.get("gem_filter") || "";
    this.controlsTarget.hidden = false;
    if (this.hasFormTarget) {
      this.submitTarget.hidden = true;
      this.updateSort();
      return;
    }
    this.statusTarget.hidden = false;
    this.filter();
  }

  disconnect() {
    clearTimeout(this.timer);
  }

  submit(event) {
    event.preventDefault();
    clearTimeout(this.timer);
    const url = new URL(this.formTarget.action);
    url.search = new URLSearchParams(new FormData(this.formTarget)).toString();
    // Share pagination's frame navigation so newer requests cancel older ones.
    Turbo.visit(url.href, {
      frame: this.formTarget.dataset.turboFrame,
      action: "advance",
    });
  }

  filter() {
    this.updateSort();
    if (this.hasFormTarget) {
      clearTimeout(this.timer);
      this.timer = setTimeout(() => this.formTarget.requestSubmit(), 250);
      return;
    }
    const query = this.inputTarget.value.trim();
    const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
    let count = 0;

    this.itemTargets.forEach((item) => {
      const matches = terms.every((term) =>
        item.dataset.gemName.toLowerCase().includes(term),
      );
      // CardComponent puts link attributes on the anchor; hide the entire row,
      // including its divider and tab stop, rather than just its contents.
      item.closest("li").hidden = !matches;
      if (matches) count++;
    });

    this.statusTarget.textContent = terms.length
      ? this.statusTarget.dataset.matches.replace("%{count}", count)
      : this.statusTarget.dataset.all;
    this.emptyTarget.hidden = count !== 0;
  }

  updateSort() {
    const query = this.inputTarget.value.trim();
    this.clearTarget.hidden = this.inputTarget.value.length === 0;

    // Sorting still navigates through GemSortable; carry the local filter with
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
