var registerCredentialForm = $("#webauthn-credential-create");
if(registerCredentialForm.length) {
  registerCredentialForm.submit(registrationHandler);
}

var signInButton = $(".js-webauthn-credential-authenticate");
if(signInButton.length) {
  signInButton.parent().submit(event => { event.preventDefault() });
  signInButton.click(signInHandler);
}

function registrationHandler(event) {
  event.preventDefault();

  $.get({
    url: "/webauthn_credentials/create_options",
    dataType: "json",
  }).done(options => {
    webauthnJSON.create({ "publicKey": options }).then(credential => {
      callback("/webauthn_credentials", $.extend(credential, { "nickname": $("#nickname").val() }));
    });
  })
}

function signInHandler(event) {
  $.get({
    url: "/session/webauthn_authentication_options",
    dataType: "json"
  }).done(options => {
    webauthnJSON.get({ "publicKey": options }).then(credential => {
      callback("session/webauthn_authentication", credential);
    });
  })
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
    console.log("WebAuthn callback error");
  });
}
