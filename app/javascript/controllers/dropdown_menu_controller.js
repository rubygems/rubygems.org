import { Controller } from "@hotwired/stimulus";

// Smallest gap, in px, between the menu and the edge of the screen.
const MARGIN = 8;

// Menu button (https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/) built
// on a native popover. The browser opens the menu from the button
// (popovertarget), closes it on Escape or an outside click, and returns focus
// to the button. This controller anchors the menu under the button, keeps
// aria-expanded in sync, and moves focus between items with the arrow keys.
export default class extends Controller {
  static targets = ["button", "menu", "item"];

  // Focus target for the next open: an item index, or null for the checked item.
  #focusOnOpen = null;

  // The menu lives in the top layer, positioned against the document, so it
  // scrolls with the page and is not clipped by overflow-hidden ancestors.
  // It lines up with the button edge nearest the side of the screen it sits
  // on (left edge for a button on the left, e.g. a wrapped mobile header),
  // kept MARGIN inside the screen once its width is known (when open).
  position() {
    const button = this.buttonTarget.getBoundingClientRect();
    const viewportWidth = document.documentElement.clientWidth;
    const maxOffset = viewportWidth - MARGIN - this.menuTarget.offsetWidth;
    const clamp = (offset) => Math.max(MARGIN, Math.min(offset, maxOffset));
    const menu = this.menuTarget.style;
    menu.top = `${button.bottom + window.scrollY + 4}px`;
    menu.minWidth = `${button.width}px`;
    if (button.left + button.width / 2 < viewportWidth / 2) {
      menu.left = `${clamp(button.left) + window.scrollX}px`;
      menu.right = "auto";
    } else {
      menu.right = `${clamp(viewportWidth - button.right) - window.scrollX}px`;
      menu.left = "auto";
    }
  }

  toggled(event) {
    const open = event.newState === "open";
    this.buttonTarget.setAttribute("aria-expanded", open);
    if (!open) return;
    this.position();
    this.#focusItem(this.#focusOnOpen ?? this.#checkedIndex());
    this.#focusOnOpen = null;
  }

  close() {
    if (this.#isOpen()) this.menuTarget.hidePopover();
  }

  buttonKeydown(event) {
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return;
    event.preventDefault();
    const index = event.key === "ArrowUp" ? this.itemTargets.length - 1 : null;
    if (this.#isOpen()) {
      this.#focusItem(index ?? this.#checkedIndex());
    } else {
      this.#focusOnOpen = index;
      this.menuTarget.showPopover();
    }
  }

  menuKeydown(event) {
    const items = this.itemTargets;
    const current = items.indexOf(document.activeElement);
    switch (event.key) {
      case "ArrowDown":
        this.#focusItem((current + 1) % items.length);
        break;
      case "ArrowUp":
        this.#focusItem((current - 1 + items.length) % items.length);
        break;
      case "Home":
        this.#focusItem(0);
        break;
      case "End":
        this.#focusItem(items.length - 1);
        break;
      case " ":
        if (current !== -1) items[current].click();
        break;
      case "Tab":
        this.close();
        return; // let focus move on to the next control
      default:
        return;
    }
    event.preventDefault();
  }

  #isOpen() {
    return this.menuTarget.matches(":popover-open");
  }

  #checkedIndex() {
    const index = this.itemTargets.findIndex(
      (item) => item.getAttribute("aria-checked") === "true",
    );
    return Math.max(index, 0);
  }

  #focusItem(index) {
    this.itemTargets[index]?.focus();
  }
}
