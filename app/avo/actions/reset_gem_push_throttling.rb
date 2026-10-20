# frozen_string_literal: true

class Avo::Actions::ResetGemPushThrottling < Avo::Actions::ApplicationAction
  self.name = "Reset Gem Push Throttling"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Reset account-level gem push throttling for #{record.handle}? IP-based limits will not be reset."
  }
  self.confirm_button_label = "Reset Throttling"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(user)
      discriminator = Rack::Attack.throttle_discriminator_normalizer.call(user.to_gid.to_s)

      Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
        key = "#{Rack::Attack::PUSH_THROTTLE_PER_USER_KEY}/#{level}:#{discriminator}"
        Rack::Attack.cache.reset_count(key, Rack::Attack::EXP_BASE_LIMIT_PERIOD**level)
      end
    end
  end
end
