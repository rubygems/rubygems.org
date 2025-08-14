# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  extend PropInitializer::Properties
  extend Phlex::Rails::HelperMacros

  # Register Rails helpers that return HTML content
  register_output_helper :icon_tag
  register_output_helper :link_to
  register_output_helper :paginate
  register_output_helper :time_tag
  register_output_helper :local_time_ago
  register_output_helper :avatar
  # Register Rails helpers that return values
  register_output_helper :page_entries_info
  register_value_helper :class_names
  register_value_helper :current_user

  def t(key, **)
    scoped_key = if key&.start_with?(".")
                   "#{self.class.translation_path}#{key}"
                 else
                   key
                 end

    result = view_context.t(scoped_key, **)
    result.html_safe? ? result : result.to_s
  end

  def self.translation_path
    @translation_path ||= name&.dup.tap do |n|
      n.gsub!(/(::[^:]+)View/, '\1')
      n.gsub!("::", ".")
      n.gsub!(/([a-z])([A-Z])/, '\1_\2')
      n.downcase!
    end
  end

  private

  def classes(*class_names)
    class_names.compact.join(" ").strip
  end
end
