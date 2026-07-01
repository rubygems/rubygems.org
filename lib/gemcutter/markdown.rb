# frozen_string_literal: true

require "action_controller"
require "kramdown"
require "rails-html-sanitizer"

module Gemcutter::Markdown
  ALLOWED_TAGS = (Rails::HTML5::SafeListSanitizer.allowed_tags + %w[
    caption table tbody td tfoot th thead tr
  ]).freeze
  ALLOWED_ATTRIBUTES = (Rails::HTML5::SafeListSanitizer.allowed_attributes + %w[id]).freeze

  def self.render(source)
    html = Kramdown::Document.new(source).to_html

    ActionController::Base.helpers.sanitize(
      html,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    )
  end
end
