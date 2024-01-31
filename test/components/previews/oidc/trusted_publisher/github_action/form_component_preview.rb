class OIDC::TrustedPublisher::GitHubAction::FormComponentPreview < Lookbook::Preview
  # @param factory select "factory for the containing trusted publisher" { choices: [oidc_rubygem_trusted_publisher, oidc_pending_trusted_publisher] }
  def default(factory: :oidc_rubygem_trusted_publisher, environment: nil, repository_name: "rubygem2", workflow_filename: "push_gem.yml")
    github_action = FactoryBot.build(:oidc_trusted_publisher_github_action, environment:, repository_name:, workflow_filename:)
    trusted_publisher = FactoryBot.build(factory, trusted_publisher: github_action)
    render Wrapper.new(form_object: trusted_publisher)
  end

  class Wrapper < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    extend Dry::Initializer
    option :form_object

    def template
      form_with(model: form_object, url: "/") do |github_action_form|
        render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(github_action_form:)
        github_action_form.submit class: "form__submit", disabled: true
      end
    end
  end
end
