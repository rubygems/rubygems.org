module DynamicErrorsHelper
  # This code was extracted from https://github.com/joelmoss/dynamic_form/blob/master/lib/action_view/helpers/dynamic_form.rb#L186
  # with a modification to fix https://github.com/rubygems/rubygems.org/issues/1834 issue. We also removed the dynamic_form
  # dependency with this.
  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys

    objects = Array.wrap(options.delete(:object) || params).map do |object|
      object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
      object = convert_to_model(object)

      if object.class.respond_to?(:model_name)
        options[:object_name] ||= object.class.model_name.human.downcase
      end

      object
    end

    objects.compact!
    count = objects.inject(0) {|sum, object| sum + object.errors.count }

    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'errorExplanation'
        end
      end
      options[:object_name] ||= params.first

      I18n.with_options :locale => options[:locale], :scope => [:errors, :template] do |locale|
        header_message = if options.include?(:header_message)
          options[:header_message]
        else
          locale.t :header, :count => count, :model => options[:object_name].to_s.gsub('_', ' ')
        end

        message = options.include?(:message) ? options[:message] : locale.t(:body)

        error_messages = objects.map do |object|
          object.errors.full_messages.map do |msg|
            content_tag(:li, msg)
          end
        end.join.html_safe

        contents = ''
        contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
        contents << content_tag(:p, message) unless message.blank?
        contents << content_tag(:ul, error_messages)

        content_tag(:div, contents.html_safe, html)
      end
    else
      ''
    end
  end
end
