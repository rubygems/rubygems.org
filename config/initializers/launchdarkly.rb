Rails.application.configure do
  launch_darkly_sdk_key = ENV["LAUNCH_DARKLY_SDK_KEY"]
  ld_config = LaunchDarkly::Config.new(
    logger: SemanticLogger[LaunchDarkly],
    offline: launch_darkly_sdk_key.blank?
  )

  config.launch_darkly_client = LaunchDarkly::LDClient.new(
    launch_darkly_sdk_key.to_s,
    ld_config
  )
end
