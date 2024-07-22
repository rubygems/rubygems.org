# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  extend Dry::Initializer

  option :rubygem_trusted_publisher

  def view_template
    title_content

    div(class: "t-body") do
      form_with(
        model: rubygem_trusted_publisher,
        url: rubygem_trusted_publishers_path(rubygem_trusted_publisher.rubygem.slug)
      ) do |f|
        f.label :trusted_publisher_type, class: "form__label"
        f.select :trusted_publisher_type, OIDC::TrustedPublisher.all.map { |type|
                                            [type.publisher_name, type.polymorphic_name]
                                          }, {}, class: "form__input form__select"

        render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(
          github_action_form: f
        )
        f.submit class: "form__submit"
      end
    end
  end

  delegate :rubygem, to: :rubygem_trusted_publisher
end
