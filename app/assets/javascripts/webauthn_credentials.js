if($(".js-webauthn-credential-create").length) {
  $(".js-webauthn-credential-create").click(registrationHandler);
}

if($("#webauthn-sign-in").length) {
  $("#webauthn-sign-in").submit(signInHandler);
}

function registrationHandler(event) {
  event.preventDefault();

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
  event.preventDefault();

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
