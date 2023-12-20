# frozen_string_literal: true

class OIDC::PendingTrustedPublishers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::DistanceOfTimeInWordsToNow
  include Phlex::Rails::Helpers::LinkTo
  extend Dry::Initializer

  option :trusted_publishers

  def template
    title_content

    div(class: "tw-space-y-2 t-body") do
      p do
        t(".description_html")
      end

      p do
        button_to t(".create"), new_profile_oidc_pending_trusted_publisher_path, class: "form__submit", method: :get
      end

      header(class: "gems__header push--s") do
        p(class: "gems__meter l-mb-0") { plain helpers.page_entries_info(trusted_publishers) }
      end

      div(class: "tw-divide-y") do
        trusted_publishers.each do |pending_trusted_publisher|
          trusted_publisher_section(pending_trusted_publisher)
        end
      end

      plain helpers.paginate(trusted_publishers)
    end
  end

  def title_content
    self.title_for_header_only = t(".title")
    content_for :title do
      h1(class: "t-display page__heading page__heading-small") do
        plain t(".title")
      end
    end
  end

  def trusted_publisher_section(pending_trusted_publisher)
    div(class: "tw-border-solid tw-my-4 tw-space-y-2 tw-flex tw-flex-col") do
      div(class: "sm:tw-flex sm:tw-flex-row tw-gap-4 tw-mt-2") do
        h3(class: "!tw-mb-0") { pending_trusted_publisher.rubygem_name }
        button_to(t(".delete"), profile_oidc_pending_trusted_publisher_path(pending_trusted_publisher),
          method: :delete, class: "form__submit form__submit--small")
      end

      div(class: "sm:tw-flex sm:tw-flex-row tw-gap-4") do
        p(class: "!tw-mb-0") { pending_trusted_publisher.trusted_publisher.class.publisher_name }
        p(class: "!tw-mb-0") do
          t(".valid_for_html",
            time_html: helpers.time_tag(pending_trusted_publisher.expires_at,
distance_of_time_in_words_to_now(pending_trusted_publisher.expires_at)))
        end
      end

      render pending_trusted_publisher.trusted_publisher
    end
  end
end
