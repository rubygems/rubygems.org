if($(".js-webauthn-credential-create").length) {
  $(".js-webauthn-credential-create").click(registrationHandler);
}

if($("#webauthn-sign-in").length) {
  $("#webauthn-sign-in").submit(signInHandler);
}

function registrationHandler(event) {
  event.preventDefault();
  getAttestationOptions().then(options => {
    registerWebauthnDevice(options).then(credential => {
      callback("/webauthn_credentials", credential);
    });
  })
}

function signInHandler(event) {
  event.preventDefault();
  getAssertionOptions().then(options => {
    verifyWebauthnDevice(options).then(credential => {
      callback("session/webauthn_authentication", credential);
    });
  })
}

function callback(url, body, type = "POST") {
  $.ajax({
    type: type,
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
