import { Controller } from "@hotwired/stimulus";

// TODO: Add suggest help text and aria-live
// https://accessibility.huit.harvard.edu/technique-aria-autocomplete
export default class extends Controller {
  static targets = ["query", "suggestions", "template", "item"];
  static classes = ["selected"];

  connect() {
    this.indexNumber = -1;
    this.suggestLength = 0;
    this.requestNumber = 0;
    this.blurFrame = null;
  }

  disconnect() {
    this.clear();
  }

  clear() {
    if (this.blurFrame) {
      cancelAnimationFrame(this.blurFrame);
      this.blurFrame = null;
    }
    this.requestNumber++;
    this.resetSuggestions();
  }

  resetSuggestions() {
    this.suggestionsTarget.classList.add("hidden");
    this.suggestionsTarget.innerHTML = "";
    this.queryTarget.classList.remove("autocomplete-loading");
    this.queryTarget.setAttribute("aria-expanded", "false");
    this.queryTarget.removeAttribute("aria-activedescendant");
    this.indexNumber = -1;
    this.suggestLength = 0;
  }

  hide(e) {
    if (e.type === "blur") {
      this.blurFrame = requestAnimationFrame(() => {
        this.blurFrame = null;
        if (!this.queryTarget.matches(":focus")) this.clear();
      });
    } else if (e.type === "keydown" || !this.queryTarget.contains(e.target)) {
      this.clear();
    }
  }

  keepFocus(e) {
    e.preventDefault();
  }

  next() {
    if (this.suggestLength === 0) return;
    this.indexNumber++;
    if (this.indexNumber >= this.suggestLength) this.indexNumber = 0;
    this.focusItem(this.itemTargets[this.indexNumber]);
  }

  prev() {
    if (this.suggestLength === 0) return;
    this.indexNumber--;
    if (this.indexNumber < 0) this.indexNumber = this.suggestLength - 1;
    this.focusItem(this.itemTargets[this.indexNumber]);
  }

  // On mouseover, highlight the item, shifting the index,
  // but don't change the input because it causes an undesireable feedback loop.
  highlight(e) {
    this.indexNumber = this.itemTargets.indexOf(e.currentTarget);
    this.focusItem(e.currentTarget, false);
  }

  choose(e) {
    this.clear();
    this.queryTarget.value = e.target.textContent;
    this.queryTarget.form.submit();
  }

  async suggest(e) {
    const el = e.currentTarget;
    const term = el.value.trim();
    // Responses can arrive out of order, so only the most recent request is applied.
    const requestNumber = ++this.requestNumber;

    if (term.length >= 2) {
      el.classList.remove("autocomplete-done");
      el.classList.add("autocomplete-loading");
      const query = new URLSearchParams({ query: term });

      try {
        const response = await fetch("/api/v1/search/autocomplete?" + query, {
          method: "GET",
        });
        const data = await response.json();
        if (requestNumber !== this.requestNumber) return;
        this.showSuggestions(data.slice(0, 10));
      } catch (error) {}
      if (requestNumber !== this.requestNumber) return;
      el.classList.remove("autocomplete-loading");
      el.classList.add("autocomplete-done");
    } else {
      this.clear();
    }
  }

  showSuggestions(items) {
    this.resetSuggestions();
    if (items.length === 0) {
      return;
    }
    items.forEach((item, idx) => this.appendItem(item, idx));
    this.suggestionsTarget.classList.remove("hidden");
    this.queryTarget.setAttribute("aria-expanded", "true");

    this.suggestLength = items.length;
    this.indexNumber = -1;
  }

  appendItem(text, idx) {
    const clone = this.templateTarget.content.cloneNode(true);
    const li = clone.querySelector("li");
    li.textContent = text;
    li.id = `suggest-${idx}`;
    this.suggestionsTarget.appendChild(clone);
  }

  focusItem(el, change = true) {
    if (!el) {
      return;
    }
    this.itemTargets.forEach((el) => {
      el.classList.remove(...this.selectedClasses);
      el.setAttribute("aria-selected", "false");
    });
    el.classList.add(...this.selectedClasses);
    el.setAttribute("aria-selected", "true");
    this.queryTarget.setAttribute("aria-activedescendant", el.id);
    if (change) {
      this.queryTarget.value = el.textContent;
      this.queryTarget.focus();
    }
  }
}
