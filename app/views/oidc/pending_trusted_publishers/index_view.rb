# frozen_string_literal: true

class OIDC::PendingTrustedPublishers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::DistanceOfTimeInWordsToNow
  include Phlex::Rails::Helpers::LinkTo

  prop :trusted_publishers, reader: :public

  def view_template
    self.title = t(".title")
    content_for(:subject) { raw(subject_sidebar) } # rubocop:disable Rails/OutputSafety -- trusted Rails partial

    h1(class: "text-h2 mb-10") { t(".title") }

    p(class: "mb-8 max-w-2xl text-b3 text-neutral-700 dark:text-neutral-300 " \
             "[&_a]:text-orange-700 [&_a]:underline dark:[&_a]:text-orange-400") do
      raw t(".description_html")
    end

    div(class: "mb-8") do
      render ButtonComponent.new(t(".create"), new_profile_oidc_pending_trusted_publisher_path)
    end

    render CardComponent.new do
      p(class: "mb-2 text-b4 text-neutral-600 dark:text-neutral-400") { page_entries_info(trusted_publishers) }

      div(class: "divide-y divide-neutral-200 dark:divide-neutral-800") do
        trusted_publishers.each { |pending_trusted_publisher| publisher_section(pending_trusted_publisher) }
      end

      div(class: "mt-4") { paginate(trusted_publishers) }
    end
  end

  private

  DANGER_BTN = "inline-flex items-center justify-center rounded border-2 border-red-500 text-red-500 " \
               "px-4 h-9 min-h-9 text-b3 hover:bg-red-500/5 active:bg-red-500/10 " \
               "dark:hover:bg-red-500/15 dark:active:bg-red-500/25 transition focus:outline-none"

  def subject_sidebar
    view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :settings })
  end

  def publisher_section(pending_trusted_publisher)
    div(class: "py-6 first:pt-0 last:pb-0") do
      div(class: "flex flex-wrap items-center justify-between gap-3") do
        h2(class: "text-b1 font-semibold text-neutral-900 dark:text-white") { pending_trusted_publisher.rubygem_name }
        button_to(t(".delete"), profile_oidc_pending_trusted_publisher_path(id: pending_trusted_publisher),
          method: :delete, class: DANGER_BTN)
      end

      p(class: "mt-1 text-b3 text-neutral-700 dark:text-neutral-300") do
        plain pending_trusted_publisher.trusted_publisher.class.publisher_name
        whitespace
        plain "·"
        whitespace
        raw t(".valid_for_html",
          time_html: view_context.time_tag(pending_trusted_publisher.expires_at,
            view_context.distance_of_time_in_words_to_now(pending_trusted_publisher.expires_at)))
      end

      render pending_trusted_publisher.trusted_publisher
    end
  end
end
