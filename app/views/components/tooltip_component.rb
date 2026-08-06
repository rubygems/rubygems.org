# frozen_string_literal: true

class TooltipComponent < ApplicationComponent
  attr_reader :text, :placement, :id, :trigger_class, :trigger_label

  PLACEMENTS = {
    top: "bottom-full mb-2",
    bottom: "top-full mt-2"
  }.freeze

  # NOTE: When using an icon instead of text, add a trigger_label for the aria-describedby
  def initialize(text:, placement: :top, id: nil, trigger_class: nil, trigger_label: nil)
    super()
    @text = text
    @placement = placement.to_sym
    @id = id || "tooltip-#{SecureRandom.alphanumeric(10)}"
    @trigger_class = trigger_class
    @trigger_label = trigger_label
  end

  def view_template(&block)
    span(class: WRAPPER) do
      button(
        type: "button",
        class: classes(TRIGGER, trigger_class),
        aria: { describedby: id, label: trigger_label }.compact,
        &block
      )
      span(id: id, role: "tooltip", class: classes(BUBBLE, PLACEMENTS.fetch(placement))) { text }
    end
  end

  WRAPPER = "group/tooltip relative inline-block"
  TRIGGER = "cursor-help rounded-sm focus:outline-2 focus:outline-offset-2 focus:outline-orange-500"
  BUBBLE = "pointer-events-none absolute left-1/2 z-20 w-max max-w-xs -translate-x-1/2 " \
           "rounded-md px-2 py-1 text-left text-b4 font-normal normal-case shadow-md " \
           "bg-neutral-900 text-white dark:bg-neutral-100 dark:text-neutral-900 " \
           "invisible opacity-0 transition-opacity duration-150 " \
           "group-hover/tooltip:visible group-hover/tooltip:opacity-100 " \
           "group-focus-within/tooltip:visible group-focus-within/tooltip:opacity-100"
end
