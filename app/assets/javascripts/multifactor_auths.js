function popUp (e) {
  e.preventDefault();
  e.returnValue = "";
};

function confirmNoRecoveryCopy (e, from) {
  if (from == null){
    e.preventDefault();
    if (confirm("Leave without copying recovery codes?")) {
      window.removeEventListener("beforeunload", popUp);
      $(this).trigger('click', ["non-null"]);
    }
  }
}

if($("#recovery-code-list").length){
  new ClipboardJS(".recovery__copy__icon");

  $(".recovery__copy__icon").on("click", function(e){
    $(this).text("[ copied ]");

    if( !$(this).is(".clicked") ) {
      e.preventDefault();
      $(this).addClass("clicked");
      window.removeEventListener("beforeunload", popUp);
      $(".form__submit").unbind("click", confirmNoRecoveryCopy);
    }
  });

  window.addEventListener("beforeunload", popUp);
  $(".form__submit").on("click", confirmNoRecoveryCopy);

  $(".form__checkbox__input").change(function() {
    if(this.checked) {
      $(".form__submit").prop('disabled', false);
    } else {
      $(".form__submit").prop('disabled', true);
    }
  });
}
