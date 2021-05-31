function popUp (e) {
  e.preventDefault();
  e.returnValue = "";
};

if($("#recovery-code-list").length){
  new Clipboard(".recovery__copy__icon");

  $(".recovery__copy__icon").on("click", function(e){
    $(this).text("[ copied ]");

    if( !$(this).is(".clicked") ) {
      e.preventDefault();
      $(this).addClass("clicked");
      window.removeEventListener("beforeunload", popUp);
    }
  });

  window.addEventListener("beforeunload", popUp);

  $(".form__checkbox__input").change(function() {
    if(this.checked) {
      $(".form__submit").prop('disabled', false);
    } else {
      $(".form__submit").prop('disabled', true);
    }
  });
}
