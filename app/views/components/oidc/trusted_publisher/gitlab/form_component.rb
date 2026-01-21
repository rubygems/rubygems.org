# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab::FormComponent < ApplicationComponent
  prop :gitlab_form, reader: :public

  def view_template
    gitlab_form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :project_path, autocomplete: :off, placeholder: "group/project"
      field trusted_publisher_form, :text_field, :ci_config_path, autocomplete: :off, optional: true, placeholder: ".gitlab-ci.yml"
      field trusted_publisher_form, :text_field, :environment, autocomplete: :off, optional: true
      field trusted_publisher_form, :select, :ref_type, [["Any", nil], %w[Tag tag], %w[Branch branch]], {}, optional: true
      field trusted_publisher_form, :text_field, :branch_name, autocomplete: :off, optional: true
    end
  end

  private

  def field(form, type, name, *args, optional: false, **options)
    form.label name, class: "form__label" do
      plain form.object.class.human_attribute_name(name)

      span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
    end

    form.send(type, name, *args, { class: class_names("form__input", "tw-border tw-border-red-500" => form.object.errors.include?(name)), **options })

    p(class: "form__field__instructions") { t("oidc.trusted_publisher.gitlab.#{name}_help_html") }
  end
end
