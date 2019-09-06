$(function(){
  if(!webauthnJSON.supported()) {
    if($("#unsupported-browser-message").length) {
      $("#unsupported-browser-message").show();

      if($("#sign-in-button").length) {
        $("#sign-in-button").prop("disabled", true);
      } else if($("#register-credential-button").length) {
        $("#register-credential-button").prop("disabled", true);
      }
    }
  }
});

var registerCredentialForm = $("#webauthn-credential-create");
if(registerCredentialForm.length) {
  registerCredentialForm.submit(registrationHandler);
}

var signInButton = $(".js-webauthn-credential-authenticate");
if(signInButton.length) {
  signInButton.parent().submit(function(event) { event.preventDefault() });
  signInButton.click(signInHandler);
}

function registrationHandler(event) {
  event.preventDefault();

  $.get({
    url: "/internal/webauthn_registration/options",
    dataType: "json",
  }).done(function(options) {
    webauthnJSON.create({ "publicKey": options }).then(
      function(credential) {
        callback("/internal/webauthn_registration", $.extend(credential, { "nickname": $("#nickname").val() }));
      },
      function(reason) {
        var registerButton = registerCredentialForm.find("input.form__submit");
        registerButton.attr('value', registerButton.attr('data-enable-with'));
        registerButton.prop('disabled', false);
      });
  }).fail(function(response) { console.log(response) })
}

function signInHandler(event) {
  $.get({
    url: "/internal/webauthn_session/options",
    dataType: "json"
  }).done(function(options) {
    webauthnJSON.get({ "publicKey": options }).then(
      function(credential) {
        callback("/internal/webauthn_session", credential);
      },
      function(reason) {
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
