document.addEventListener("DOMContentLoaded", () => {
  // Remove nested fields
  document.addEventListener("click", (e) => {
    const removeButton = e.target.closest("button.form__remove_nested_button");
    if (!removeButton) return;
    e.preventDefault();
    const nestedField = removeButton.closest(".form__nested_fields");
    if (nestedField) nestedField.remove();
  });

  // Add nested fields
  document.addEventListener("click", (e) => {
    const addButton = e.target.closest("button.form__add_nested_button");
    if (!addButton) return;
    e.preventDefault();
    const parent = addButton.parentElement;
    if (!parent) return;
    const templateSibling = Array.from(parent.children).find((el) =>
      el.matches("template.form__nested_fields"),
    );
    if (!templateSibling) return;
    const html = templateSibling.innerHTML.replace(/NEW_OBJECT/g, Date.now());
    parent.insertAdjacentHTML("beforeend", html);
  });
});
