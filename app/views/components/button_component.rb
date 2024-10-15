# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  attr_reader :text, :href, :type, :options, :color_css, :size_css

  def initialize(text = nil, href: nil, type: :button, color: :primary, outline: false, size: :large, **options) # rubocop:disable Metrics/ParameterLists
    super()
    @text = text
    @href = href
    @type = type
    @options = options
    @options[:name] ||= nil
    @color_css = button_color(color, outline)
    @size_css = button_size(size)
  end

  def view_template(&)
    css = "text-nowrap font-semibold no-underline " \
          "rounded inline-flex border-box " \
          "justify-content-center items-center hover:shadow-md " \
          "transition duration-200 ease-in-out focus:outline-none " \
          "#{color_css} #{size_css} #{options.delete(:class)}"

    if type == :link
      link_to text, href, class: css, **options, &
    elsif href
      button_to text, href, class: css, **options, &
    else
      button(class: css, type:, **options, &)
    end
  end

  private

  def button_color(color, outline)
    color = color.to_sym
    color = :orange if color == :primary
    color = :orange2 if color == :secondary
    @color_css = outline ? OUTLINE_BUTTON_COLOR[color] : FILL_BUTTON_COLOR[color]
  end

  def button_size(size)
    case size
    when :small # 36px height
      "px-4 py-3 h-9 min-h-9 text-b3"
    else # :large, 44px height
      "px-4 py-3 h-12 min-h-12 text-b2" \
    end
  end

  FILL_BUTTON_COLOR = {
    orange:    "text-white bg-orange-500 hover:bg-orange-600 active:bg-orange-600 " \
               "dark:bg-orange-500 dark:hover:bg-orange-700 dark:active:bg-orange-700",
    orange2:   "text-neutral-800 bg-orange-200 hover:bg-orange-300 active:bg-orange-300 " \
               "dark:text-white dark:bg-orange-800 dark:hover:bg-orange-900 dark:active:bg-orange-900",
    yellow:    "text-neutral-800 bg-yellow-500 hover:bg-yellow-600 active:bg-yellow-600 " \
               "dark:text-white dark:bg-yellow-500 dark:hover:bg-yellow-900 dark:active:bg-yellow-900",
    blue:      "text-white bg-blue-500 hover:bg-blue-600 active:bg-blue-600 " \
               "dark:bg-blue-500 dark:hover:bg-blue-700 dark:active:bg-blue-700",
    green:     "text-white bg-green-500 hover:bg-green-600 active:bg-green-600 " \
               "dark:bg-green-500 dark:hover:bg-green-700 dark:active:bg-green-700",
    red:       "text-white bg-red-500 hover:bg-red-600 active:bg-red-600 " \
               "dark:bg-red-500 dark:hover:bg-red-700 dark:active:bg-red-700",
    neutral:   "text-white bg-neutral-700 hover:bg-neutral-600 active:bg-neutral-600 " \
               "dark:bg-neutral-700 dark:hover:bg-neutral-700 dark:active:bg-neutral-700"
  }.freeze

  # rubocop:disable Layout/LineLength
  OUTLINE_BUTTON_COLOR = {
    orange:    "border-2 border-orange-500 text-orange-500 hover:border-orange-600 hover:text-orange-600 active:border-orange-600 active:text-orange-600 " \
               "dark:border-orange-500 dark:text-orange-500 dark:hover:border-orange-700 dark:hover:text-orange-700 dark:active:border-orange-700 dark:active:text-orange-700",
    orange2:   "border-2 border-orange-200 text-orange-200 hover:border-orange-300 hover:text-orange-300 active:border-orange-300 active:text-orange-300 " \
               "dark:border-orange-800 dark:text-orange-800 dark:hover:border-orange-900 dark:hover:text-orange-900 dark:active:border-orange-900 dark:active:text-orange-900",
    yellow:    "border-2 border-yellow-500 text-yellow-500 hover:border-yellow-600 hover:text-yellow-600 active:border-yellow-600 active:text-yellow-600 " \
               "dark:border-yellow-500 dark:text-yellow-500 dark:hover:border-yellow-900 dark:hover:text-yellow-900 dark:active:border-yellow-900 dark:active:text-yellow-900",
    blue:      "border-2 border-blue-500 text-blue-500 hover:border-blue-600 hover:text-blue-600 active:border-blue-600 active:text-blue-600 " \
               "dark:border-blue-500 dark:text-blue-500 dark:hover:border-blue-700 dark:hover:text-blue-700 dark:active:border-blue-700 dark:active:text-blue-700",
    green:     "border-2 border-green-500 text-green-500 hover:border-green-600 hover:text-green-600 active:border-green-600 active:text-green-600 " \
               "dark:border-green-500 dark:text-green-500 dark:hover:border-green-700 dark:hover:text-green-700 dark:active:border-green-700 dark:active:text-green-700",
    red:       "border-2 border-red-500 text-red-500 hover:border-red-600 hover:text-red-600 active:border-red-600 active:text-red-600 " \
               "dark:border-red-500 dark:text-red-500 dark:hover:border-red-700 dark:hover:text-red-700 dark:active:border-red-700 dark:active:text-red-700",
    neutral:   "border-2 border-neutral-700 text-neutral-700 hover:border-neutral-600 hover:text-neutral-600 active:border-neutral-600 active:text-neutral-600 " \
               "dark:border-neutral-700 dark:text-neutral-700 dark:hover:border-neutral-700 dark:hover:text-neutral-700 dark:active:border-neutral-700 dark:active:text-neutral-700"
  }.freeze
  # rubocop:enable Layout/LineLength
end
