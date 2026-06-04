# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab::FormComponentPreview < Lookbook::Preview
  # @param factory select "factory for the containing trusted publisher" { choices: [oidc_rubygem_trusted_publisher, oidc_pending_trusted_publisher] }
  def default(factory: :oidc_rubygem_trusted_publisher, environment: nil, project_path: "group/project", ci_config_path: ".gitlab-ci.yml")
    gitlab = FactoryBot.build(:oidc_trusted_publisher_gitlab, environment:, project_path:, ci_config_path:)
    trusted_publisher = FactoryBot.build(factory, trusted_publisher: gitlab)
    render Wrapper.new(form_object: trusted_publisher)
  end

  class Wrapper < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    extend PropInitializer::Properties

    prop :form_object

    def view_template
      form_with(model: @form_object, url: "/") do |f|
        render OIDC::TrustedPublisher::GitLab::FormComponent.new(form: f)
        f.submit class: "form__submit", disabled: true
      end
    end
  end
end
