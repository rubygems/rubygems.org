# frozen_string_literal: true

class AlertComponent < ApplicationComponent
  attr_reader :style, :closeable

  def initialize(style: :notice, closeable: false)
    super()
    @style = style.to_sym
    @style = :notice if @style == :notice_html
    @style = :neutral unless STYLES.key?(@style)
    @closeable = closeable
  end

  def view_template(&)
    color, icon_color, icon = STYLES.fetch(style)
    data = { controller: "reveal", reveal_target: "item" } if closeable
    p(data:, class: "flex flex-row items-center p-4 mb-10 rounded border text-b2 #{color} justify-between") do
      span(class: "flex flex-row items-center") do
        unsafe_raw helpers.icon_tag(icon, size: 8, class: "#{icon_color} mr-3 h-8 w-8")
        span(class: "align-middle", &)
      end
      if closeable
        button(data: { action: "click->reveal#hide" }, title: t("hide"), class: "h-8 w-8 ml-6 items-center justify-center outline-none") do
          unsafe_raw helpers.icon_tag("close", class: "w-6 h-6", aria: { label: t("hide") })
        end
      end
    end
  end

  COLORS = {
    orange:  "border-orange-500 bg-orange-200 text-neutral-800 " \
             "dark:bg-orange-900 dark:text-white",
    yellow:  "border-yellow-500 bg-yellow-200 text-neutral-800 " \
             "dark:bg-yellow-900 dark:text-white",
    blue:    "border-blue-500 bg-blue-200 text-neutral-800 " \
             "dark:bg-blue-900 dark:text-white",
    green:   "border-green-500 bg-green-200 text-neutral-800 " \
             "dark:bg-green-900 dark:text-white",
    red:     "border-red-500 bg-red-200 text-neutral-800 " \
             "dark:bg-red-900 dark:text-white",
    neutral: "border-neutral-500 bg-neutral-200 text-neutral-800 " \
             "dark:bg-neutral-900 dark:text-white"
  }.freeze

  ICON_COLORS = {
    orange:  "fill-orange-500",
    yellow:  "fill-yellow-600",
    blue:    "fill-blue-500",
    green:   "fill-green-500",
    red:     "fill-red-400",
    neutral: "fill-neutral-800 dark:fill-neutral-500"
  }.freeze

  STYLES = {
    error:   [COLORS[:red],     ICON_COLORS[:red],     "error"],
    alert:   [COLORS[:yellow],  ICON_COLORS[:yellow],  "warning"],
    notice:  [COLORS[:blue],    ICON_COLORS[:blue],    "arrow-circle-right"],
    success: [COLORS[:green],   ICON_COLORS[:green],   "check-circle"],
    primary: [COLORS[:orange],  ICON_COLORS[:orange],  "arrow-circle-right"],
    neutral: [COLORS[:neutral], ICON_COLORS[:neutral], "arrow-circle-right"]
  }.freeze
end
