Rails.application.configure do
  ld_config = LaunchDarkly::Config.new(
    logger: SemanticLogger[LaunchDarkly],
    offline: Rails.application.secrets.launch_darkly_sdk_key.blank?
  )

  config.launch_darkly_client = LaunchDarkly::LDClient.new(
    Rails.application.secrets.launch_darkly_sdk_key.to_s,
    ld_config
  )
end
