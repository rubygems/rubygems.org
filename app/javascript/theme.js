// Loaded as a blocking script in <head> so a saved theme applies before first paint.
(() => {
  let theme = null;
  try {
    theme = localStorage.getItem("theme");
  } catch {
    // Storage can be blocked; fall back to the system preference.
  }
  document.documentElement.dataset.theme = ["light", "dark"].includes(theme)
    ? theme
    : "auto";
})();
