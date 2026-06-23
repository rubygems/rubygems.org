# frozen_string_literal: true

class CopyFieldComponent < ApplicationComponent
  attr_reader :value, :label_text, :name, :aria_label

  def initialize(value:, label: nil, name: nil, aria_label: nil)
    super()
    @value = value
    @label_text = label
    @name = name
    @aria_label = aria_label
  end

  def view_template
    div(class: "flex flex-col gap-1 sm:flex-row sm:items-center sm:gap-4") do
      render_label
      div(
        class: FIELD,
        data: {
          controller: "clipboard",
          clipboard_success_content_value: t("copied")
        }
      ) do
        input(
          type: :text,
          value:,
          id: name,
          name:,
          readonly: true,
          class: INPUT,
          aria: ({ label: aria_label } if label_text.blank? && aria_label.present?),
          data: { clipboard_target: "source" }
        )
        copy_button
      end
    end
  end

  FIELD = "flex flex-1 min-w-0 items-center gap-2 px-4 py-2 rounded border " \
          "border-neutral-300 dark:border-neutral-700 bg-white dark:bg-neutral-950 " \
          "text-neutral-800 dark:text-neutral-200"
  INPUT = "flex-1 min-w-0 font-mono text-c4 bg-transparent focus:outline-none"
  BUTTON = "shrink-0 p-1 rounded text-b4 cursor-pointer " \
           "text-neutral-700 dark:text-neutral-400 " \
           "hover:bg-neutral-100 hover:text-neutral-800 active:bg-neutral-200 " \
           "dark:hover:bg-neutral-800 dark:hover:text-white dark:active:bg-neutral-700 " \
           "transition duration-200 ease-in-out"

  private

  def copy_button
    button(
      type: :button,
      class: BUTTON,
      title: t("copy_to_clipboard"),
      aria: { label: t("copy_to_clipboard") },
      data: {
        action: "click->clipboard#copy",
        clipboard_target: "button"
      }
    ) do
      icon_tag("content-copy", size: 5, class: "pointer-events-none")
    end
  end

  def render_label
    return unless label_text

    label(
      for: name,
      class: "shrink-0 sm:w-16 capitalize text-b4 text-neutral-700 dark:text-neutral-400"
    ) { label_text }
  end
end
