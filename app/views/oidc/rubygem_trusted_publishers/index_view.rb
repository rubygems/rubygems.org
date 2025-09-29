# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  prop :rubygem, reader: :public
  prop :trusted_publishers, reader: :public
  prop :trusted_publisher_types, reader: :private

  def view_template
    title_content

    div(class: "tw-space-y-2 t-body") do
      p do
        t(".description_html")
      end

      div(class: "tw-flex tw-gap-2 tw-mb-4") do # New section for provider selection
        trusted_publisher_types.each do |type|
          link_to "Add #{type.publisher_name} Trusted Publisher",
new_rubygem_trusted_publisher_path(rubygem.slug, trusted_publisher_provider: type.url_identifier), class: "form__submit"
        end
      end

      header(class: "gems__header push--s") do
        p(class: "gems__meter l-mb-0") { plain page_entries_info(trusted_publishers) }
      end

      div(class: "tw-divide-y") do
        trusted_publishers.each do |rubygem_trusted_publisher|
          div(class: "tw-border-solid tw-my-4 tw-space-y-4 tw-flex tw-flex-col") do
            div(class: "sm:tw-flex sm:tw-items-baseline tw-mt-4 tw-gap-2") do
              h4 { rubygem_trusted_publisher.trusted_publisher.class.publisher_name }
              button_to(t(".delete"), rubygem_trusted_publisher_path(rubygem.slug, rubygem_trusted_publisher),
                        method: :delete, class: "form__submit form__submit--small")
            end
            render rubygem_trusted_publisher.trusted_publisher
          end
        end
      end

      plain paginate(trusted_publishers)
    end
  end
end
