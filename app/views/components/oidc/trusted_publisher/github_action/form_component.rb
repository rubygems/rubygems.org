# frozen_string_literal: true

class OIDC::TrustedPublisher::GitHubAction::FormComponent < ApplicationComponent
  extend Dry::Initializer

  option :github_action_form

  def template
    github_action_form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :repository_owner, autocomplete: :off
      field trusted_publisher_form, :text_field, :repository_name, autocomplete: :off
      field trusted_publisher_form, :text_field, :workflow_filename, autocomplete: :off
      field trusted_publisher_form, :text_field, :environment, autocomplete: :off, optional: true
    end
  end

  private

  def field(form, type, name, optional: false, **opts)
    form.label name, class: "form__label" do
      plain form.object.class.human_attribute_name(name)
      span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
    end
    form.send type, name, class: helpers.class_names("form__input", "tw-border tw-border-red-500" => form.object.errors.include?(name)), **opts
    p(class: "form__field__instructions") { t("oidc.trusted_publisher.github_actions.#{name}_help_html") }
  end
end
