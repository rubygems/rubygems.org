# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::LinkTo
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  prop :rubygem, reader: :public
  prop :trusted_publishers, reader: :public

  def view_template
    gem_subject_page do
      p(class: "max-w-2xl text-b3 text-neutral-700 dark:text-neutral-300 " \
               "[&_a]:text-orange-700 [&_a]:underline dark:[&_a]:text-orange-400") do
        raw t(".description_html")
      end

      div do
        render ButtonComponent.new(t(".create"), new_rubygem_trusted_publisher_path(rubygem.slug), method: "get")
      end

      render CardComponent.new do
        p(class: "mb-2 text-b4 text-neutral-600 dark:text-neutral-400 uppercase tracking-wide") do
          page_entries_info(trusted_publishers)
        end

        div(class: "divide-y divide-neutral-200 dark:divide-neutral-800") do
          trusted_publishers.each { |rubygem_trusted_publisher| publisher_section(rubygem_trusted_publisher) }
        end

        div(class: "mt-4") { paginate(trusted_publishers) }
      end
    end
  end

  private

  DANGER_BTN = "inline-flex items-center justify-center rounded border-2 border-red-500 text-red-500 " \
               "px-4 h-9 min-h-9 text-b3 hover:bg-red-500/5 active:bg-red-500/10 " \
               "dark:hover:bg-red-500/15 dark:active:bg-red-500/25 transition focus:outline-none"

  def publisher_section(rubygem_trusted_publisher)
    div(class: "py-6 first:pt-0 last:pb-0 space-y-4") do
      div(class: "flex flex-wrap items-center justify-between gap-3") do
        h2(class: "text-b1 font-semibold text-neutral-900 dark:text-white") do
          plain rubygem_trusted_publisher.trusted_publisher.class.publisher_name
        end
        button_to(t(".delete"), rubygem_trusted_publisher_path(rubygem.slug, rubygem_trusted_publisher),
          method: :delete, class: DANGER_BTN)
      end

      render rubygem_trusted_publisher.trusted_publisher
    end
  end
end
