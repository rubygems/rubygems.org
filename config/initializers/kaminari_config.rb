# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 30
  # config.max_per_page = nil
  # config.window = 4
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.params_on_first_page = false
end

module Kaminari::Helpers
  PARAM_KEY_EXCEPT_LIST = %i[authenticity_token commit utf8 _method script_name original_script_name].freeze
end
