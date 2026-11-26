import { Controller } from "@hotwired/stimulus";

const MAX_SUGGESTIONS = 5;

// TODO: Add suggest help text and aria-live
// https://accessibility.huit.harvard.edu/technique-aria-autocomplete
export default class extends Controller {
  static targets = ["query", "suggestions", "template", "ctaTemplate", "item"];
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

  next(e) {
    if (this.suggestLength === 0) return;
    e.preventDefault();
    this.indexNumber++;
    if (this.indexNumber >= this.suggestLength) this.indexNumber = 0;
    this.focusItem(this.itemTargets[this.indexNumber]);
  }

  prev(e) {
    if (this.suggestLength === 0) return;
    e.preventDefault();
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

  // Enter follows the highlighted row's link; with nothing highlighted the form submits (full search).
  submit(e) {
    const link = this.itemTargets[this.indexNumber];
    this.clear();
    if (link) {
      e.preventDefault();
      window.location.assign(link.href);
    }
  }

  async suggest(e) {
    const el = e.currentTarget;
    const term = el.value.trim();
    // Responses can arrive out of order, so only the most recent request is applied.
    const requestNumber = ++this.requestNumber;

    if (term.length >= 2) {
      el.classList.remove("autocomplete-done");
      el.classList.add("autocomplete-loading");
      const query = new URLSearchParams({ query: term, details: "true" });

      try {
        const response = await fetch("/api/v1/search/autocomplete?" + query, {
          method: "GET",
        });
        const data = await response.json();
        if (requestNumber !== this.requestNumber) return;
        this.showSuggestions(data.slice(0, MAX_SUGGESTIONS), term);
      } catch (error) {}
      if (requestNumber !== this.requestNumber) return;
      el.classList.remove("autocomplete-loading");
      el.classList.add("autocomplete-done");
    } else {
      this.clear();
    }
  }

  showSuggestions(items, term) {
    this.resetSuggestions();
    if (items.length === 0) {
      return;
    }
    this.term = term;
    items.forEach((item, idx) => this.appendItem(item, idx));
    this.appendCta(term);
    this.suggestionsTarget.classList.remove("hidden");
    this.queryTarget.setAttribute("aria-expanded", "true");

    this.suggestLength = this.itemTargets.length;
    this.indexNumber = -1;
  }

  appendItem(gem, idx) {
    const clone = this.templateTarget.content.cloneNode(true);
    const link = clone.querySelector("a");
    link.id = `suggest-${idx}`;
    link.href = `/gems/${encodeURIComponent(gem.name)}`;
    link.dataset.name = gem.name;
    this.fill(clone, "name", gem.name);
    this.fill(clone, "version", gem.version);
    this.fill(clone, "summary", gem.summary);
    this.fill(clone, "downloads", this.compactNumber(gem.downloads));
    this.suggestionsTarget.appendChild(clone);
  }

  appendCta(term) {
    const clone = this.ctaTemplateTarget.content.cloneNode(true);
    const link = clone.querySelector("a");
    link.id = "suggest-all";
    const url = new URL(this.queryTarget.form.action);
    url.searchParams.set("query", term);
    link.href = url;
    this.fill(clone, "query", term);
    this.suggestionsTarget.appendChild(clone);
  }

  fill(root, field, value) {
    root.querySelector(`[data-autocomplete-field="${field}"]`).textContent =
      value ?? "";
  }

  compactNumber(number) {
    return new Intl.NumberFormat(document.documentElement.lang || undefined, {
      notation: "compact",
      maximumFractionDigits: 1,
    }).format(number);
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
    // Gem rows mirror their name into the input; the "see all" row restores the typed query.
    if (change) {
      this.queryTarget.value = el.dataset.name ?? this.term;
      this.queryTarget.focus();
    }
  }
}
