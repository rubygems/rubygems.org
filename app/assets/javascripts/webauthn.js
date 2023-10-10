import $ from "jquery";
 import {
   create,
   parseCreationOptionsFromJSON,
   get,
   parseRequestOptionsFromJSON,
 } from "@github/webauthn-json/browser-ponyfill";

(function() {
  const handleEvent = function(event) {
    event.preventDefault();
    return event.target;
  };

  const setError = function(submit, error, message) {
    submit.attr("disabled", false);
    error.attr("hidden", false);
    error.text(message);
  };

  const handleHtmlResponse = function(submit, responseError, response) {
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

  const credentialsToBase64 = function(credentials) {
    return {
      type: credentials.type,
      id: credentials.id,
      rawId: bufferToBase64url(credentials.rawId),
      clientExtensionResults: credentials.clientExtensionResults,
      response: {
        authenticatorData: bufferToBase64url(credentials.response.authenticatorData),
        attestationObject: bufferToBase64url(credentials.response.attestationObject),
        clientDataJSON: bufferToBase64url(credentials.response.clientDataJSON),
        signature: bufferToBase64url(credentials.response.signature),
        userHandle: bufferToBase64url(credentials.response.userHandle),
      },
    };
  };

  $(function() {
    const credentialForm = $(".js-new-webauthn-credential--form");
    const credentialError = $(".js-new-webauthn-credential--error");
    const credentialSubmit = $(".js-new-webauthn-credential--submit");
    const csrfToken = $("[name='csrf-token']").attr("content");

    credentialForm.submit(function(event) {
      const form = handleEvent(event);
      const nickname = $(".js-new-webauthn-credential--nickname").val();

      fetch(form.action + ".json", {
        method: "POST",
        credentials: "same-origin",
        headers: { "X-CSRF-Token": csrfToken }
      }).then(function (response) {
        return response.json();
      }).then(function (json) {
        return create({
          publicKey: parseCreationOptionsFromJSON(json)
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
        response.json().then(function (json) {
          if (json.redirect_url) {
            window.location.href = json.redirect_url;
          } else {
            setError(credentialSubmit, credentialError, json.message);
          }
        }).catch(function (error) {
          setError(credentialSubmit, credentialError, error);
        });
      }).catch(function (error) {
        setError(credentialSubmit, credentialError, error);
      });
    });
  });

  const getCredentials = async function(event, csrfToken) {
    const form = handleEvent(event);
    const options = JSON.parse(form.dataset.options);
    const credentials = await get({
      publicKey: parseRequestOptionsFromJSON(options)
    });
    return await fetch(form.action, {
      method: "POST",
      credentials: "same-origin",
      redirect: "follow",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        credentials: credentialsToBase64(credentials),
      })
    });
  };

  $(function() {
    const cliSessionForm = $(".js-webauthn-session-cli--form");
    const cliSessionError = $(".js-webauthn-session-cli--error");
    const csrfToken = $("[name='csrf-token']").attr("content");

    function failed_verification_url(message) {
      const url =  new URL(`${location.origin}/webauthn_verification/failed_verification`);
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
    const sessionForm = $(".js-webauthn-session--form");
    const sessionSubmit = $(".js-webauthn-session--submit");
    const sessionError = $(".js-webauthn-session--error");
    const csrfToken = $("[name='csrf-token']").attr("content");

    sessionForm.submit(async function(event) {
      try {
        const response = await getCredentials(event, csrfToken);
        handleHtmlResponse(sessionSubmit, sessionError, response);
      } catch (error) {
        setError(sessionSubmit, sessionError, error);
      }
    });
  });
})();
