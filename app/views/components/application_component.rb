# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes

  class TranslationHelper
    include ActionView::Helpers::TranslationHelper

    def initialize(translation_path:)
      @translation_path = translation_path
    end

    private

    def scope_key_by_partial(key)
      return key unless key&.start_with?(".")

      "#{@translation_path}#{key}"
    end
  end

  delegate :t, to: "self.class.translation_helper"

  def self.translation_helper
    @translation_helper ||= TranslationHelper.new(translation_path: translation_path)
  end

  def self.translation_path
    @translation_path ||= name&.dup.tap do |n|
      n.gsub!(/(::[^:]+)View/, '\1')
      n.gsub!("::", ".")
      n.gsub!(/([a-z])([A-Z])/, '\1_\2')
      n.downcase!
    end
  end
end
