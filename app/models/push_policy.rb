PushPolicy = Gem::Security::Policy.new(
  "Push Policy",
  verify_data:   true,
  verify_signer: true,
  verify_chain:  true,
  verify_root:   true,
  only_trusted:  false,
  only_signed:   false
)
