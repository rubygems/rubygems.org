(function() {
  var handleEvent = function(event) {
    event.preventDefault();
    return event.target;
  };

  var setError = function(submit, error, message) {
    submit.attr("disabled", false);
    error.attr("hidden", false);
    error.text(message);
  };

  var handleJsonResponse = function(submit, responseError, response) {
    if (response.redirected) {
      window.location.href = response.url;
    } else {
      response.json().then(function (json) {
        setError(submit, responseError, json.message);
      }).catch(function (error) {
        setError(submit, responseError, error);
      });
    }
  };

  var handleHtmlResponse = function(submit, responseError, response) {
    if (response.redirected) {
      window.location.href = response.url;
    } else {
      response.text().then(function (html) {
        document.body.innerHTML = html;
      }).catch(function (error) {
        setError(submit, responseError, error);
      });
    }
  };

  var credentialsToBase64 = function(credentials) {
    return {
      type: credentials.type,
      id: credentials.id,
      rawId: bufferToBase64url(credentials.rawId),
      clientExtensionResults: credentials.clientExtensionResults,
      response: {
        authenticatorData: bufferToBase64url(credentials.response.authenticatorData),
        attestationObject: bufferToBase64url(credentials.response.attestationObject),
        clientDataJSON: bufferToBase64url(credentials.response.clientDataJSON),
        signature: bufferToBase64url(credentials.response.signature)
      },
    };
  };

  var credentialsToBuffer = function(credentials) {
    return credentials.map(function(credential) {
      return {
        id: base64urlToBuffer(credential.id),
        type: credential.type
      };
    });
  };

  $(function() {
    var credentialForm = $(".js-new-webauthn-credential--form");
    var credentialError = $(".js-new-webauthn-credential--error");
    var credentialSubmit = $(".js-new-webauthn-credential--submit");
    var csrfToken = $("[name='csrf-token']").attr("content");

    credentialForm.submit(function(event) {
      var form = handleEvent(event);
      var nickname = $(".js-new-webauthn-credential--nickname").val();

      fetch(form.action + ".json", {
        method: "POST",
        credentials: "same-origin",
        headers: { "X-CSRF-Token": csrfToken }
      }).then(function (response) {
        return response.json();
      }).then(function (json) {
        json.user.id = base64urlToBuffer(json.user.id);
        json.challenge = base64urlToBuffer(json.challenge);
        json.excludeCredentials = credentialsToBuffer(json.excludeCredentials);
        return navigator.credentials.create({
          publicKey: json
        });
      }).then(function (credentials) {
        return fetch(form.action + "/callback.json", {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            credentials: credentialsToBase64(credentials),
            webauthn_credential: { nickname: nickname }
          })
        });
      }).then(function (response) {
        handleJsonResponse(credentialSubmit, credentialError, response);
      }).catch(function (error) {
        setError(credentialSubmit, credentialError, error);
      });
    });
  });

  var getCredentials = function(event, csrfToken) {
    var form = handleEvent(event);
    var options = JSON.parse(form.dataset.options);
    options.challenge = base64urlToBuffer(options.challenge);
    options.allowCredentials = credentialsToBuffer(options.allowCredentials);
    return navigator.credentials.get({
      publicKey: options
    }).then(function (credentials) {
      return fetch(form.action, {
        method: "POST",
        credentials: "same-origin",
        redirect: "follow",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          credentials: credentialsToBase64(credentials)
        })
      });
    })
  };

  $(function() {
    var cliSessionForm = $(".js-webauthn-session-cli--form");
    var cliSessionError = $(".js-webauthn-session-cli--error");
    var csrfToken = $("[name='csrf-token']").attr("content");

    function failed_verification_url(message) {
      var url =  new URL(`${location.origin}/webauthn_verification/failed_verification`);
      url.searchParams.append("error", message);
      return url.href;
    };

    cliSessionForm.submit(function(event) {
      getCredentials(event, csrfToken).then(function (response) {
        response.text().then(function (text) {
          if (text == "success") {
            window.location.href = `${location.origin}/webauthn_verification/successful_verification`;
          } else {
            window.location.href = failed_verification_url(text);
          }
        });
      }).catch(function (error) {
        window.location.href = failed_verification_url(error.message);
      });
    });
  });

  $(function() {
    var sessionForm = $(".js-webauthn-session--form");
    var sessionSubmit = $(".js-webauthn-session--submit");
    var sessionError = $(".js-webauthn-session--error");
    var csrfToken = $("[name='csrf-token']").attr("content");

    sessionForm.submit(function(event) {
      getCredentials(event, csrfToken).then(function (response) {
        handleHtmlResponse(sessionSubmit, sessionError, response);
      }).catch(function (error) {
        setError(sessionSubmit, sessionError, error);
      });
    });
  });
})();
