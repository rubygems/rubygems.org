module DynamicErrorsHelper
  # This code was extracted from https://github.com/joelmoss/dynamic_form/blob/master/lib/action_view/helpers/dynamic_form.rb#L186
  # with a modification to fix https://github.com/rubygems/rubygems.org/issues/1834 issue. We also removed the dynamic_form
  # dependency with this.
  def error_messages_for(object, object_name = "user")
    count = object.errors.count
    return '' if count.zero?

    html = {}
    %i[id class].each do |key|
      html[key] = 'errorExplanation'
    end

    I18n.with_options scope: %i[errors template] do |locale|
      header_message = locale.t(:header, count: count, model: object_name.to_s.tr('_', ' '))
      message = locale.t(:body)

      error_messages = safe_join(object.errors.full_messages.map do |msg|
        content_tag(:li, msg)
      end)

      contents = []
      contents << content_tag(:h2, header_message) if header_message.present?
      contents << content_tag(:p, message) if message.present?
      contents << content_tag(:ul, error_messages)

      content_tag(:div, safe_join(contents), html)
    end
  end
end
