# frozen_string_literal: true

class OIDC::TrustedPublisher::FormComponent < ApplicationComponent
  prop :form, reader: :public

  private

  def field(form, type, name, *args, optional: false, **options) # rubocop:disable Metrics/ParameterLists
    div class: "py-4" do
      form.label name, class: label_class do
        plain form.object.class.human_attribute_name(name)
        span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
      end

      input_class = class_names(
        type == :select ? select_class : field_class,
        "tw-border tw-border-red-500" => form.object.errors.include?(name)
      )
      form.send(type, name, *args, { class: input_class, **options })

      p(class: note_class) { t("oidc.trusted_publisher.#{form.object.class.url_identifier}.#{name}_help_html") }
    end
  end

  def label_class
    "block text-b4 font-semibold text-neutral-800 dark:text-neutral-200 mb-2"
  end

  def field_class
    "block w-full rounded border border-neutral-300 dark:border-neutral-700 " \
      "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white px-3 h-12 " \
      "outline-none focus:border-neutral-500 focus:ring-0"
  end

  def select_class
    "block w-full rounded border border-neutral-300 dark:border-neutral-700 " \
      "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white px-3 h-12 " \
      "outline-none focus:border-neutral-500 focus:ring-0"
  end

  def note_class
    "mt-1 text-b4 text-neutral-600 dark:text-neutral-400 " \
      "[&_a]:text-orange-700 [&_a]:underline dark:[&_a]:text-orange-400"
  end
end
