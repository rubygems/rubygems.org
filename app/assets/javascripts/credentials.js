function getAttestationOptions() {
  return $.get({
    url: "/webauthn_credentials/create_options",
    dataType: "json",
  })
}
function registerWebauthnDevice(credentialCreationOptions){
  console.log("Creating new public key credentials...");
  return webauthnJSON.create({ "publicKey": credentialCreationOptions });
}

function getAssertionOptions() {
  return $.get({
    url: "/session/webauthn_authentication_options",
    dataType: "json"
  })
}
function verifyWebauthnDevice(credentialsRequestOptions){
  console.log("Getting public key credentials...");
  return webauthnJSON.get({ "publicKey": credentialsRequestOptions });
}
