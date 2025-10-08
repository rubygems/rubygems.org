# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab::FormComponent < ApplicationComponent
  prop :gitlab_form, reader: :public

  def view_template
    gitlab_form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :project_path, autocomplete: :off
      field trusted_publisher_form, :text_field, :ref_path, autocomplete: :off
      field trusted_publisher_form, :text_field, :environment, autocomplete: :off, optional: true
      field trusted_publisher_form, :text_field, :ci_config_ref_uri, autocomplete: :off, optional: true
    end
  end

  private

  def field(form, type, name, optional: false, **)
    form.label name, class: "form__label" do
      plain form.object.class.human_attribute_name(name)

      span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
    end
    form.send(type, name, class: class_names("form__input", "tw-border tw-border-red-500" => form.object.errors.include?(name)), **)
    p(class: "form__field__instructions") { t("oidc.trusted_publisher.gitlab.#{name}_help_html") }
  end
end
