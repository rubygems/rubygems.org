import { Controller } from "@hotwired/stimulus";

// Replaces a broken avatar image with the user's initials on a neutral
// background instead of the browser's broken image icon.
export default class extends Controller {
  static values = { initials: String };

  connect() {
    if (this.element.complete && this.element.naturalWidth === 0) {
      this.fallback();
    }
  }

  fallback() {
    const fallback = document.createElement("span");
    fallback.textContent = this.initialsValue;
    fallback.setAttribute("role", "img");
    if (this.element.alt) {
      fallback.setAttribute("aria-label", this.element.alt);
    }
    fallback.className = this.element.className;
    fallback.style.width = `${this.element.width}px`;
    fallback.style.height = `${this.element.height}px`;
    fallback.classList.add(
      "inline-flex",
      "items-center",
      "justify-center",
      "shrink-0",
      "rounded",
      "bg-neutral-200",
      "dark:bg-neutral-800",
      "text-neutral-600",
      "dark:text-neutral-400",
      "text-b4",
      "font-semibold",
    );
    this.element.replaceWith(fallback);
  }
}
