Rails.application.configure do
  config.launch_darkly_client = LaunchDarkly::LDClient.new(ENV["LAUNCH_DARKLY_SDK_KEY"].presence || "")
end
