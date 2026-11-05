import { Controller } from "@hotwired/stimulus";

const THEMES = ["auto", "light", "dark"];

export default class extends Controller {
  cycle() {
    const root = document.documentElement;
    const theme =
      THEMES[(THEMES.indexOf(root.dataset.theme) + 1) % THEMES.length];
    root.dataset.theme = theme;
    try {
      localStorage.setItem("theme", theme);
    } catch {
      // Storage can be blocked; the choice then lasts until the next page load.
    }
  }
}
