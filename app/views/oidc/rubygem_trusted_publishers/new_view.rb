# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  prop :rubygem_trusted_publisher, reader: :public

  def view_template
    title_content

    div(class: "t-body") do
      p do
        "New Trusted Publisher: #{rubygem_trusted_publisher.trusted_publisher.class.publisher_name}"
      end
      form_with(
        model: rubygem_trusted_publisher,
        url: rubygem_trusted_publishers_path(rubygem_trusted_publisher.rubygem.slug)
      ) do |f|
        f.hidden_field :trusted_publisher_type

        render form_component(f)
        f.submit class: "form__submit"
      end
    end
  end

  delegate :rubygem, to: :rubygem_trusted_publisher

  private

  def form_component(form)
    case rubygem_trusted_publisher.trusted_publisher
    when OIDC::TrustedPublisher::Buildkite then OIDC::TrustedPublisher::Buildkite::FormComponent.new(buildkite_form: form)
    when OIDC::TrustedPublisher::GitHubAction then OIDC::TrustedPublisher::GitHubAction::FormComponent.new(github_action_form: form)
    else
      raise "oh no"
    end
  end
end
