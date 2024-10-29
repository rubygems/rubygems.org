# frozen_string_literal: true

class Subject::NavComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :current

  def initialize(current: :dashboard)
    @current = current
    super()
  end

  def view_template(&)
    div(class: "relative -mx-8 lg:mx-0") do
      nav(data: { controller: "scroll" }, class: NAV, &)
      div class: "#{GRADIENT} w-12 right-0 bg-gradient-to-l" # Gradient fade right
      div class: "#{GRADIENT} w-8 left-0 bg-gradient-to-r" # Gradient fade left
    end
  end

  NAV = "relative flex overflow-x-auto no-scrollbar whitespace-nowrap py-4 space-x-2 pl-8 pr-12 " \
        "lg:flex-col lg:px-0 lg:space-x-0 lg:space-y-2"
  GRADIENT = "lg:hidden absolute top-0 h-full pointer-events-none from-white dark:from-black"
  LINK = "flex items-center space-x-2 h-12 lg:h-14 px-3 py-1 lg:px-6 lg:py-2 rounded"
  ACTIVE_LINK = "#{LINK} bg-orange-100 dark:bg-orange-900 text-neutral-900 dark:text-white".freeze
  INACTIVE_LINK = "#{LINK} bg-neutral-050 text-neutral-600 hover:bg-neutral-200 " \
                  "dark:bg-neutral-950 dark:text-neutral-400 dark:hover:bg-neutral-800".freeze

  def link(text, url, icon:, name: nil, **options)
    is_current = name == current
    data = { scroll_target: "scrollLeft" } if is_current
    options[:class] = "#{options[:class]} #{is_current ? ACTIVE_LINK : INACTIVE_LINK}"
    link_to(url, data:, **options) do
      unsafe_raw helpers.icon_tag(icon, size: 7, class: is_current && "text-orange-500")
      span { text }
    end
  end
end
