# frozen_string_literal: true

class OIDC::TrustedPublisher::FormComponent < ApplicationComponent
  prop :form, reader: :public

  private

  def field(form, type, name, *args, **options)
    optional = options.delete(:optional) { false }
    form.label name, class: "form__label" do
      plain form.object.class.human_attribute_name(name)

      span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
    end

    form.send(type, name, *args, { class: class_names("form__input", "tw-border tw-border-red-500" => form.object.errors.include?(name)), **options })

    p(class: "form__field__instructions") { t("oidc.trusted_publisher.#{form.object.class.url_identifier}.#{name}_help_html") }
  end
end
