# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab::FormComponent < OIDC::TrustedPublisher::FormComponent
  def view_template
    form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :project_path, autocomplete: :off, placeholder: "group/project"
      field trusted_publisher_form, :text_field, :ci_config_path, autocomplete: :off, optional: true, placeholder: ".gitlab-ci.yml"
      field trusted_publisher_form, :text_field, :environment, autocomplete: :off, optional: true
      field trusted_publisher_form, :select, :ref_type, [["Any", nil], %w[Tag tag], %w[Branch branch]], {}, optional: true
      field trusted_publisher_form, :text_field, :branch_name, autocomplete: :off, optional: true
    end
  end
end
