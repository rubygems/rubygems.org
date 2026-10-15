import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "controls",
    "input",
    "item",
    "status",
    "empty",
    "clear",
    "sort",
  ];

  connect() {
    if (!this.hasInputTarget) return;

    this.inputTarget.value =
      new URL(window.location.href).searchParams.get("gem_filter") || "";
    this.controlsTarget.hidden = false;
    this.statusTarget.hidden = false;
    this.filter();
  }

  filter() {
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
    this.clearTarget.hidden = this.inputTarget.value.length === 0;

    // Sorting still navigates through GemSortable; carry the local filter with
    // it without changing global search, the sort cookie, or the current URL.
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
