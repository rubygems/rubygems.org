import { Controller } from "@hotwired/stimulus";

// Polls the total download count and animates the homepage ticker with
// NumberFlow. The server-rendered count stays in place until NumberFlow loads.
export default class extends Controller {
  static targets = ["count"];
  static values = {
    url: String,
    count: Number,
    interval: { type: Number, default: 10000 },
  };

  connect() {
    this.enhance();
    this.timer = setInterval(() => this.refresh(), this.intervalValue);
  }

  disconnect() {
    clearInterval(this.timer);
    this.abortController?.abort();
  }

  async enhance() {
    try {
      await import("number-flow");
    } catch {
      return; // Keep the plain server-rendered count.
    }
    if (!this.element.isConnected || this.flow) return;

    const flow = document.createElement("number-flow");
    flow.locales = document.documentElement.lang || undefined;
    flow.update(this.countValue);
    this.countTarget.replaceChildren(flow);
    this.flow = flow;
  }

  async refresh() {
    if (document.hidden) return;

    this.abortController?.abort();
    this.abortController = new AbortController();

    try {
      const response = await fetch(this.urlValue, {
        // Fastly passes requests carrying session cookies to Rails; the count is the same for everyone.
        credentials: "omit",
        headers: { Accept: "application/json" },
        signal: this.abortController.signal,
      });
      if (!response.ok) return;

      const { total } = await response.json();
      if (Number.isSafeInteger(total)) this.countValue = total;
    } catch {
      // Keep showing the last known count on network errors or aborts.
    }
  }

  countValueChanged(count, previous) {
    if (previous === undefined) return; // Initial value is already rendered.

    if (this.flow) {
      this.flow.update(count);
    } else if (this.hasCountTarget) {
      this.countTarget.textContent = new Intl.NumberFormat(
        document.documentElement.lang || undefined,
      ).format(count);
    }
  }
}
