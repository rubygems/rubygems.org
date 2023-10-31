$(function () {
  function wire() {
    var removeNestedButtons = $("button.form__remove_nested_button");

    removeNestedButtons.off("click");
    removeNestedButtons.click(function (e) {
      e.preventDefault();
      var button = $(this);
      var nestedField = button.closest(".form__nested_fields");

      nestedField.remove();
    });

    var addNestedButtons = $("button.form__add_nested_button");
    addNestedButtons.off("click");
    addNestedButtons.click(function (e) {
      e.preventDefault();
      var button = $(this);
      var nestedFields = button.siblings("template.form__nested_fields");

      var content = nestedFields
        .html()
        .replace(/NEW_OBJECT/g, new Date().getTime());

      $(content).insertAfter(button.siblings().last());

      wire();
    });
  }

  wire();
});
