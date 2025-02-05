# frozen_string_literal: true

class OIDC::TrustedPublisher::Buildkite::FormComponent < ApplicationComponent
  prop :buildkite_form, reader: :public

  def view_template
    buildkite_form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :organization_slug, autocomplete: :off
      field trusted_publisher_form, :text_field, :pipeline_slug, autocomplete: :off
    end
  end

  private

  def field(form, type, name, optional: false, **)
    form.label name, class: "form__label" do
      plain form.object.class.human_attribute_name(name)
      span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
    end
    form.send(type, name, class: helpers.class_names("form__input", "tw-border tw-border-red-500" => form.object.errors.include?(name)), **)
    p(class: "form__field__instructions") { t("oidc.trusted_publisher.buildkite.#{name}_help_html") }
  end
end

