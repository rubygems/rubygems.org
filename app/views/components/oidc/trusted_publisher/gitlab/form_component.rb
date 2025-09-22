# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab::FormComponent < ApplicationComponent
  prop :form, reader: :public

  def view_template
    form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :namespace_path, autocomplete: :off
      field trusted_publisher_form, :text_field, :project_path, autocomplete: :off
    end
  end

  private

  def field(form, type, name, optional: false, **)
    attribute_owner_class = begin
      form.object.trusted_publisher.class
    rescue StandardError
      nil
    end

    form.label name, class: "form__label" do
      plain attribute_owner_class&.human_attribute_name(name) || name.to_s.humanize
      span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
    end
    form.send(type, name, class: class_names("form__input", "tw-border tw-border-red-500" => form.object.errors.include?(name)), **)
    p(class: "form__field__instructions") { t("oidc.trusted_publisher.gitlab.#{name}_help_html") }
  end
end
