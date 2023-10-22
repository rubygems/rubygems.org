# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include ActionView::Helpers::TranslationHelper

  def self.translation_path
    @translation_path ||= name&.dup.tap do |n|
      n.gsub!(/(::[^:]+)View/, '\1')
      n.gsub!("::", ".")
      n.gsub!(/([a-z])([A-Z])/, '\1_\2')
      n.downcase!
    end
  end

  private

  def scope_key_by_partial(key)
    return key unless key&.start_with?(".")

    "#{self.class.translation_path}#{key}"
  end
end
