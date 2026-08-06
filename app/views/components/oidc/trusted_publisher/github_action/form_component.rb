# frozen_string_literal: true

class OIDC::TrustedPublisher::GitHubAction::FormComponent < OIDC::TrustedPublisher::FormComponent
  def view_template
    form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :repository_owner, autocomplete: :off
      field trusted_publisher_form, :text_field, :repository_name, autocomplete: :off
      field trusted_publisher_form, :text_field, :workflow_filename, autocomplete: :off
      field trusted_publisher_form, :text_field, :environment, autocomplete: :off, optional: true
      field trusted_publisher_form, :text_field, :workflow_repository_owner, autocomplete: :off, optional: true
      field trusted_publisher_form, :text_field, :workflow_repository_name, autocomplete: :off, optional: true
    end
  end
end
