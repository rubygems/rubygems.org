# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  attr_reader :args, :type, :options, :color, :size, :style

  def initialize(*args, type: :button, size: :large, color: :primary, style: :fill, **options) # rubocop:disable Metrics/ParameterLists
    super()
    @args = args
    @type = type
    @size = size
    @color = color
    @style = style
    @options = options
    @options[:name] ||= nil
  end

  def view_template(&block)
    css = "text-nowrap no-underline " \
          "rounded inline-flex border-box " \
          "justify-content-center items-center hover:shadow-md " \
          "#{DISABLED} disabled:cursor-default disabled:hover:shadow-none " \
          "transition duration-200 ease-in-out focus:outline-none " \
          "#{button_color(color, style)} #{button_size(size)} #{options.delete(:class)}"

    if type == :link
      link_to(*args, class: css, **options, &block)
    elsif (args.size == 1 && block_given?) || args.size == 2
      button_to(*args, class: css, method: :get, **options, &block)
    else
      block ||= proc { args.first }
      button(class: css, type:, **options, &block)
    end
  end

  private

  def button_color(color, style)
    color = color.to_sym
    color = :orange if color == :primary
    color = :hammy if color == :secondary
    STYLES[style][color]
  end

  def button_size(size)
    case size
    when :small # 36px height
      "px-4 py-3 h-9 min-h-9 text-b3"
    else # :large, 44px height
      "px-4 py-3 h-12 min-h-12 text-b2"
    end
  end

  DISABLED = "disabled:bg-neutral-200 disabled:border-neutral-200 disabled:text-neutral-600 " \
             "dark:disabled:bg-neutral-800 dark:disabled:border-neutral-800 dark:disabled:text-neutral-600"

  FILL_BUTTON_COLOR = {
    red:     "text-white bg-red-500 hover:bg-red-600 active:bg-red-600 " \
             "dark:bg-red-500 dark:hover:bg-red-600 dark:active:bg-red-600",
    orange:  "text-white bg-orange-500 hover:bg-orange-600 active:bg-orange-600 " \
             "dark:bg-orange-500 dark:hover:bg-orange-700 dark:active:bg-orange-700",
    hammy:   "text-orange-900 bg-orange-200 hover:bg-orange-300 active:bg-orange-300 " \
             "dark:text-white dark:bg-orange-800 dark:hover:bg-orange-900 dark:active:bg-orange-900",
    yellow:  "text-neutral-800 bg-yellow-500 hover:bg-yellow-600 active:bg-yellow-600 " \
             "dark:text-white dark:bg-yellow-500 dark:hover:bg-yellow-600 dark:active:bg-yellow-600",
    green:   "text-white bg-green-500 hover:bg-green-600 active:bg-green-600 " \
             "dark:bg-green-500 dark:hover:bg-green-700 dark:active:bg-green-700",
    blue:    "text-white bg-blue-500 hover:bg-blue-600 active:bg-blue-600 " \
             "dark:bg-blue-500 dark:hover:bg-blue-700 dark:active:bg-blue-700",
    neutral: "text-white bg-neutral-700 hover:bg-neutral-600 active:bg-neutral-600 " \
             "dark:bg-neutral-700 dark:hover:bg-neutral-800 dark:active:bg-neutral-800"
  }.freeze

  PLAIN_BUTTON_COLOR = {
    red:     "text-red-500 hover:bg-red-500/5 active:bg-red-500/10 " \
             "dark:hover:bg-red-500/15 dark:active:bg-red-500/25 ",
    orange:  "text-orange-500 hover:bg-orange-500/5 active:bg-orange-500/10 " \
             "dark:hover:bg-orange-500/15 dark:active:bg-orange-500/25 ",
    hammy:   "text-orange-800 hover:bg-orange-200/15 active:bg-orange-200/25 " \
             "dark:text-orange-200 dark:hover:bg-orange-200/15 dark:active:bg-orange-200/25 ",
    yellow:  "text-yellow-500 hover:bg-yellow-500/5 active:bg-yellow-500/10 " \
             "dark:hover:bg-yellow-500/15 dark:active:bg-yellow-500/25 ",
    green:   "text-green-500 hover:bg-green-500/5 active:bg-green-500/10 " \
             "dark:hover:bg-green-500/15 dark:active:bg-green-500/25 ",
    blue:    "text-blue-500 hover:bg-blue-500/5 active:bg-blue-500/10 " \
             "dark:hover:bg-blue-500/15 dark:active:bg-blue-500/25 ",
    neutral: "text-neutral-700 hover:bg-neutral-700/5 active:bg-neutral-700/10 " \
             "dark:text-white dark:hover:bg-white/15 dark:active:bg-white/25"
  }.freeze

  OUTLINE_BUTTON_COLOR = {
    red:     "#{PLAIN_BUTTON_COLOR[:red]} border-2 border-red-500",
    orange:  "#{PLAIN_BUTTON_COLOR[:orange]} border-2 border-orange-500",
    hammy:   "#{PLAIN_BUTTON_COLOR[:hammy]} border-2 border-orange-800 dark:border-orange-200",
    yellow:  "#{PLAIN_BUTTON_COLOR[:yellow]} border-2 border-yellow-500",
    green:   "#{PLAIN_BUTTON_COLOR[:green]} border-2 border-green-500",
    blue:    "#{PLAIN_BUTTON_COLOR[:blue]} border-2 border-blue-500",
    neutral: "#{PLAIN_BUTTON_COLOR[:neutral]} border-2 border-neutral-700 dark:border-white"
  }.freeze

  STYLES = {
    fill: FILL_BUTTON_COLOR,
    outline: OUTLINE_BUTTON_COLOR,
    plain: PLAIN_BUTTON_COLOR
  }.freeze
end
