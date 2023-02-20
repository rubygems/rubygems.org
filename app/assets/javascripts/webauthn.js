import $ from 'jquery';
import {create, parseCreationOptionsFromJSON, get, parseRequestOptionsFromJSON} from '@github/webauthn-json/browser-ponyfill';

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
        return create(parseCreationOptionsFromJSON({
          publicKey: json
        }))
      }).then(function (credentials) {
        return fetch(form.action + "/callback.json", {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            credentials: credentials,
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

  $(function() {
    var sessionForm = $(".js-webauthn-session--form");
    var sessionSubmit = $(".js-webauthn-session--submit");
    var sessionError = $(".js-webauthn-session--error");
    var csrfToken = $("[name='csrf-token']").attr("content");

    sessionForm.submit(function(event) {
      var form = handleEvent(event);
      var options = JSON.parse(form.dataset.options);
      get(parseRequestOptionsFromJSON({
        publicKey: options
      })).then(function (credentials) {
        return fetch(form.action, {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            credentials: credentials
          })
        });
      }).then(function (response) {
        handleHtmlResponse(sessionSubmit, sessionError, response);
      }).catch(function (error) {
        setError(sessionSubmit, sessionError, error);
      });
    });
  });
})();
