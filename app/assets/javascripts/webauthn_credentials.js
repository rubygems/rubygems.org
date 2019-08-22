var registerCredentialsButton = $(".js-webauthn-credential-create");
if(registerCredentialsButton.length) {
  registerCredentialsButton.parent().submit(event => { event.preventDefault() });
  registerCredentialsButton.click(registrationHandler);
}

var signInButton = $(".js-webauthn-credential-authenticate");
if(signInButton.length) {
  signInButton.parent().submit(event => { event.preventDefault() });
  signInButton.click(signInHandler);
}

function registrationHandler(event) {
  $.get({
    url: "/webauthn_credentials/create_options",
    dataType: "json",
  }).done(options => {
    webauthnJSON.create({ "publicKey": options }).then(credential => {
      callback("/webauthn_credentials", credential);
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
