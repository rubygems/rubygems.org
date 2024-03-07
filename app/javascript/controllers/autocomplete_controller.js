import { Controller } from "@hotwired/stimulus"

// TODO: Add suggest help text and aria-live
// https://accessibility.huit.harvard.edu/technique-aria-autocomplete
export default class extends Controller {
  static targets = ["query", "suggestions", "template", "item"]
  static classes = ["selected"]

  connect() {
    this.indexNumber = -1;
    this.suggestLength = 0;
  }

  disconnect() { clear() }

  clear() {
    this.suggestionsTarget.innerHTML = ""
    this.suggestionsTarget.removeAttribute('tabindex');
    this.suggestionsTarget.removeAttribute('aria-activedescendant');
  }

  hide(e) {
    // Allows adjusting the cursor in the input without hiding the suggestions.
    if (!this.queryTarget.contains(e.target)) this.clear()
  }

  next() {
    this.indexNumber++;
    if (this.indexNumber >= this.suggestLength) this.indexNumber = 0;
    this.focusItem(this.itemTargets[this.indexNumber]);
  }

  prev() {
    this.indexNumber--;
    if (this.indexNumber < 0) this.indexNumber = this.suggestLength - 1;
    this.focusItem(this.itemTargets[this.indexNumber]);
  }

  // On mouseover, highlight the item, shifting the index,
  // but don't change the input because it causes an undesireable feedback loop.
  highlight(e) {
    this.indexNumber = this.itemTargets.indexOf(e.currentTarget)
    this.focusItem(e.currentTarget, false)
  }

  choose(e) {
    this.clear();
    this.queryTarget.value = e.target.textContent;
    this.queryTarget.form.submit();
  }

  async suggest(e) {
    const el = e.currentTarget;
    const term = el.value.trim();

    if (term.length >= 2) {
      el.classList.remove('autocomplete-done');
      el.classList.add('autocomplete-loading');
      const query = new URLSearchParams({ query: term })

      try {
        const response = await fetch('/api/v1/search/autocomplete?' + query, { method: 'GET' })
        const data = await response.json()
        this.showSuggestions(data.slice(0, 10))
      } catch (error) { }
      el.classList.remove('autocomplete-loading');
      el.classList.add('autocomplete-done');
    } else {
      this.clear()
    }
  }

  showSuggestions(items) {
    this.clear();
    if (items.length === 0) {
      return;
    }
    items.forEach((item, idx) => this.appendItem(item, idx));
    this.suggestionsTarget.setAttribute('tabindex', 0);
    this.suggestionsTarget.setAttribute('role', 'listbox');

    this.suggestLength = items.length;
    this.indexNumber = -1;
  };

  appendItem(text, idx) {
    const clone = this.templateTarget.content.cloneNode(true);
    const li = clone.querySelector('li')
    li.textContent = text;
    li.id = `suggest-${idx}`;
    this.suggestionsTarget.appendChild(clone)
  }

  focusItem(el, change = true) {
    this.itemTargets.forEach(el => el.classList.remove(this.selectedClass))
    el.classList.add(this.selectedClass);
    this.suggestionsTarget.setAttribute('aria-activedescendant', el.id);
    if (change) {
      this.queryTarget.value = el.textContent;
      this.queryTarget.focus();
    }
  }
}
