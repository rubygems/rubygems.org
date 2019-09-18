$(function(){
  if(!webauthnJSON.supported()) {
    if($("#unsupported-browser-message").length) {
      $("#unsupported-browser-message").show();

      $(".js-webauthn-button").each(function() {
        $(this).prop("disabled", true);
      });
    }
  }
});

$(".js-webauthn-registration-form").submit(registrationHandler);
$(".js-webauthn-authentication-form").submit(signInHandler);

function registrationHandler(event) {
  event.preventDefault();
  $("#security-key-error-message").hide();
  var $form = $(this);

  $.get({
    url: "/internal/webauthn_registration/options",
    dataType: "json",
  }).done(function(options) {
    webauthnJSON.create({ "publicKey": options }).then(
      function(credential) {
        callback("/internal/webauthn_registration", $.extend(credential, { "nickname": $("#nickname").val() }));
      },
      function(reason) {
        $("#security-key-error-message").show();
        var registerButton = $form.find("input.form__submit");
        registerButton.attr('value', registerButton.attr('data-enable-with'));
        registerButton.prop('disabled', false);
      });
  }).fail(function(response) { console.log(response) })
}

function signInHandler(event) {
  event.preventDefault();
  $("#security-key-error-message").hide();
  var $form = $(this);

  $.get({
    url: "/internal/webauthn_session/options",
    dataType: "json"
  }).done(function(options) {
    webauthnJSON.get({ "publicKey": options }).then(
      function(credential) {
        callback("/internal/webauthn_session", credential);
      },
      function(reason) {
        $("#security-key-error-message").show();
        signInButton = $form.find(".js-webauthn-button");
        signInButton.attr('value', signInButton.attr('data-enable-with'));
        signInButton.prop('disabled', false);
      });
  }).fail(function(response) { window.location.replace(response.responseJSON["redirect_path"]) })
}

function callback(url, body) {
  $.post({
    url: url,
    data: JSON.stringify(body),
    dataType: "json",
    headers: {
      "Content-Type": "application/json"
    }
  }).done(function(response) {
    window.location.replace(response["redirect_path"]);
  }).error(function(response) {
    window.location.replace(response.responseJSON["redirect_path"]);
  });
}
