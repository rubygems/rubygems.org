# frozen_string_literal: true

class Rubygem::TabNavComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :current

  def initialize(current:)
    @current = current
    super()
  end

  def view_template(&)
    div(class: "-mx-8 lg:mx-0") do
      nav(data: { controller: "scroll" }, class: NAV, aria: { label: t("rubygems.show.tabs.label") }, &)
    end
  end

  NAV = "relative flex overflow-x-auto no-scrollbar whitespace-nowrap " \
        "border-b border-neutral-200 dark:border-neutral-800"
  # Tabs stack icon-over-label and share the width on mobile; inline icon + label from lg up.
  TAB = "flex flex-1 flex-col items-center gap-1 px-1 py-2 text-b4 " \
        "lg:flex-none lg:flex-row lg:gap-2 lg:px-4 lg:py-3 lg:text-b3 -mb-px border-b-2"
  ACTIVE_TAB = "#{TAB} border-orange-500 text-neutral-900 dark:text-white font-semibold".freeze
  INACTIVE_TAB = "#{TAB} border-transparent text-neutral-700 hover:text-neutral-800 hover:border-neutral-300 " \
                 "dark:text-neutral-400 dark:hover:text-white dark:hover:border-neutral-700".freeze
  DISABLED_TAB = "#{TAB} border-transparent text-neutral-400 dark:text-neutral-700 cursor-default".freeze

  def tab(text, url, icon:, name: nil, **options)
    is_current = name == current
    data = { scroll_target: "scrollLeft" } if is_current
    options[:class] = "#{options[:class]} #{is_current ? ACTIVE_TAB : INACTIVE_TAB}"
    options[:aria] = (options[:aria] || {}).merge(current: "page") if is_current
    link_to(url, data:, **options) do
      icon_tag(icon, size: 5, class: is_current && "text-orange-500")
      span { text }
    end
  end

  def disabled_tab(text, icon:)
    span(class: DISABLED_TAB, aria: { disabled: "true" }) do
      icon_tag(icon, size: 5)
      span { text }
    end
  end
end
