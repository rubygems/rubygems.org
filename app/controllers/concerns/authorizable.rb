module Authorizable
  extend ActiveSupport::Concern

  class_methods do
    def authorize_rubygem(action_map)
      before_action do
        action = action_map[params[:action].to_sym]
        action && authorize(@rubygem, action)
      end
    end
  end
end
