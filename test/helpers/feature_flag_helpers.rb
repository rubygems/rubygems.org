module FeatureFlagHelpers
  def enable_feature(flag_name, actor: nil)
    if actor
      FeatureFlag.enable_for_actor(flag_name, actor)
    else
      FeatureFlag.enable_globally(flag_name)
    end
  end

  def disable_feature(flag_name)
    FeatureFlag.disable(flag_name)
  end

  def with_feature(flag_name, enabled: true, actor: nil)
    if enabled
      enable_feature(flag_name, actor: actor)
    else
      disable_feature(flag_name)
    end

    yield
  ensure
    disable_feature(flag_name)
  end
end
