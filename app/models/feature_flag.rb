# frozen_string_literal: true

class FeatureFlag
  ORGANIZATIONS = :organizations
  CONTENT_ADDRESSABLE_GEM_PUSHES = :content_addressable_gem_pushes

  class << self
    def enabled?(flag_name, actor = nil)
      Flipper.enabled?(flag_name, actor)
    end

    def enable_globally(flag_name)
      Flipper.enable(flag_name)
    end

    def disable_globally(flag_name)
      Flipper.disable(flag_name)
    end

    def enable_for_actor(flag_name, actor)
      Flipper.enable_actor(flag_name, actor)
    end

    def disable_for_actor(flag_name, actor)
      Flipper.disable_actor(flag_name, actor)
    end

    def enable_percentage(flag_name, percentage)
      Flipper.enable_percentage_of_actors(flag_name, percentage)
    end
  end
end
