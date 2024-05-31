# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor
  include OIDC::RubygemTrustedPublishers::Concerns::Title
  extend Dry::Initializer

  option :rubygem
  option :trusted_publishers

  def view_template
    title_content

    div(class: "tw-space-y-2 t-body") do
      p do
        t(".description_html")
      end

      p do
        button_to t(".create"), new_rubygem_trusted_publisher_path(rubygem.slug), class: "form__submit", method: :get
      end

      header(class: "gems__header push--s") do
        p(class: "gems__meter l-mb-0") { plain helpers.page_entries_info(trusted_publishers) }
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

      plain helpers.paginate(trusted_publishers)
    end
  end
end
