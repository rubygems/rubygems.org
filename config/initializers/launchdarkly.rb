Rails.application.configure do
  LaunchDarkly::Config.singleton_class.prepend(Module.new do
    def default_logger = SemanticLogger[LaunchDarkly]
  end)

  config.launch_darkly_client = LaunchDarkly::LDClient.new(ENV["LAUNCH_DARKLY_SDK_KEY"].presence || "")
end
