import { bufferToBase64url, base64urlToBuffer } from "webauthn-json";

(function () {
  const handleEvent = function (event) {
    event.preventDefault();
    return event.target;
  };

  const setError = function (submit, error, message) {
    if (submit) {
      submit.disabled = false;
    }
    if (error) {
      error.hidden = false;
      error.textContent = String(message);
    }
  };

  const handleHtmlResponse = function (submit, responseError, response) {
    if (response.redirected) {
      window.location.href = response.url;
    } else {
      response
        .text()
        .then(function (html) {
          document.body.innerHTML = html;
        })
        .catch(function (error) {
          setError(submit, responseError, error);
        });
    }
  };

  const credentialsToBase64 = function (credentials) {
    return {
      type: credentials.type,
      id: credentials.id,
      rawId: bufferToBase64url(credentials.rawId),
      clientExtensionResults: credentials.clientExtensionResults,
      response: {
        authenticatorData: bufferToBase64url(
          credentials.response.authenticatorData,
        ),
        attestationObject: bufferToBase64url(
          credentials.response.attestationObject,
        ),
        clientDataJSON: bufferToBase64url(credentials.response.clientDataJSON),
        signature: bufferToBase64url(credentials.response.signature),
        userHandle: bufferToBase64url(credentials.response.userHandle),
      },
    };
  };

  const credentialsToBuffer = function (credentials) {
    return credentials.map(function (credential) {
      return {
        id: base64urlToBuffer(credential.id),
        type: credential.type,
      };
    });
  };

  const parseCreationOptionsFromJSON = function (json) {
    return {
      ...json,
      challenge: base64urlToBuffer(json.challenge),
      user: { ...json.user, id: base64urlToBuffer(json.user.id) },
      excludeCredentials: credentialsToBuffer(json.excludeCredentials),
    };
  };

  const parseRequestOptionsFromJSON = function (json) {
    return {
      ...json,
      challenge: base64urlToBuffer(json.challenge),
      allowCredentials: credentialsToBuffer(json.allowCredentials),
    };
  };

  const getCsrfToken = function (form) {
    const input = form.querySelector("input[name='authenticity_token']");
    return input ? input.value : "";
  };

  const onReady = (fn) => {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  };

  onReady(() => {
    const credentialForm = document.querySelector(
      ".js-new-webauthn-credential--form",
    );
    if (!credentialForm) {
      return;
    }
    const credentialError = document.querySelector(
      ".js-new-webauthn-credential--error",
    );
    const credentialSubmit = document.querySelector(
      ".js-new-webauthn-credential--submit",
    );
    const csrfToken = getCsrfToken(credentialForm);
    const callbackCsrfToken = credentialForm.dataset.callbackCsrfToken;

    credentialForm.addEventListener("submit", function (event) {
      const form = handleEvent(event);
      const nicknameInput = document.querySelector(
        ".js-new-webauthn-credential--nickname",
      );
      const nickname = nicknameInput ? nicknameInput.value : "";

      fetch(form.action, {
        method: "POST",
        credentials: "same-origin",
        headers: { "X-CSRF-Token": csrfToken, Accept: "application/json" },
      })
        .then(function (response) {
          return response.json();
        })
        .then(function (json) {
          return navigator.credentials.create({
            publicKey: parseCreationOptionsFromJSON(json),
          });
        })
        .then(function (credentials) {
          return fetch(form.action + "/callback", {
            method: "POST",
            credentials: "same-origin",
            headers: {
              "X-CSRF-Token": callbackCsrfToken,
              "Content-Type": "application/json",
              Accept: "application/json",
            },
            body: JSON.stringify({
              credentials: credentialsToBase64(credentials),
              webauthn_credential: { nickname: nickname },
            }),
          });
        })
        .then(function (response) {
          response
            .json()
            .then(function (json) {
              if (json.redirect_url) {
                window.location.href = json.redirect_url;
              } else {
                setError(credentialSubmit, credentialError, json.message);
              }
            })
            .catch(function (error) {
              setError(credentialSubmit, credentialError, error);
            });
        })
        .catch(function (error) {
          setError(credentialSubmit, credentialError, error);
        });
    });
  });

  const getCredentials = async function (event, csrfToken) {
    const form = handleEvent(event);
    const options = JSON.parse(form.dataset.options);
    const credentials = await navigator.credentials.get({
      publicKey: parseRequestOptionsFromJSON(options),
    });
    return await fetch(form.action, {
      method: "POST",
      credentials: "same-origin",
      redirect: "follow",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        credentials: credentialsToBase64(credentials),
      }),
    });
  };

  onReady(() => {
    const cliSessionForm = document.querySelector(
      ".js-webauthn-session-cli--form",
    );
    if (!cliSessionForm) {
      return;
    }
    const cliSessionError = document.querySelector(
      ".js-webauthn-session-cli--error",
    );
    const csrfToken = getCsrfToken(cliSessionForm);

    function failed_verification_url(message) {
      const url = new URL(
        `${location.origin}/webauthn_verification/failed_verification`,
      );
      url.searchParams.append("error", message);
      return url.href;
    }

    cliSessionForm.addEventListener("submit", function (event) {
      getCredentials(event, csrfToken)
        .then(function (response) {
          response.text().then(function (text) {
            if (text == "success") {
              window.location.href = `${location.origin}/webauthn_verification/successful_verification`;
            } else {
              window.location.href = failed_verification_url(text);
            }
          });
        })
        .catch(function (error) {
          window.location.href = failed_verification_url(error.message);
        });
    });
  });

  onReady(() => {
    const sessionForm = document.querySelector(".js-webauthn-session--form");
    if (!sessionForm) {
      return;
    }
    const sessionSubmit = document.querySelector(
      ".js-webauthn-session--submit",
    );
    const sessionError = document.querySelector(".js-webauthn-session--error");
    const csrfToken = getCsrfToken(sessionForm);

    sessionForm.addEventListener("submit", async function (event) {
      try {
        const response = await getCredentials(event, csrfToken);
        handleHtmlResponse(sessionSubmit, sessionError, response);
      } catch (error) {
        setError(sessionSubmit, sessionError, error);
      }
    });
  });
})();
