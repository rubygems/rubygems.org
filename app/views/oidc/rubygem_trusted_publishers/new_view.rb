# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  prop :rubygem_trusted_publisher, reader: :public

  delegate :rubygem, to: :rubygem_trusted_publisher

  def view_template
    gem_subject_page do
      render CardComponent.new do
        form_with(
          model: rubygem_trusted_publisher,
          url: rubygem_trusted_publishers_path(rubygem.slug)
        ) do |f|
          div class: "py-4" do
            f.label :trusted_publisher_type, class: label_class
            f.select :trusted_publisher_type,
              OIDC::TrustedPublisher.all.map { |type| [type.publisher_name, type.polymorphic_name] },
              {}
          end

          render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(
            github_action_form: f
          )

          render ButtonComponent.new do
            f.submit
          end
        end
      end
    end
  end

  private

  def label_class
    "block text-b4 font-semibold text-neutral-800 dark:text-neutral-200 mb-2"
  end
end
