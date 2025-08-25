// gem page
document.addEventListener("DOMContentLoaded", () => {
  const toggleMfaSections = () => {
    document
      .querySelectorAll(".gem__users__mfa-text.mfa-warn")
      .forEach((el) => {
        el.classList.toggle("t-item--hidden");
      });
    document.querySelectorAll(".gem__users__mfa-disabled").forEach((el) => {
      el.classList.toggle("t-item--hidden");
    });
  };

  document.querySelectorAll(".gem__users__mfa-text.mfa-warn").forEach((el) => {
    el.addEventListener("click", toggleMfaSections);
  });
});
