# frozen_string_literal: true

class OIDC::TrustedPublisher::GitHubAction::FormComponent < ApplicationComponent
  prop :github_action_form, reader: :public

  def view_template
    github_action_form.fields_for :trusted_publisher do |trusted_publisher_form|
      field trusted_publisher_form, :text_field, :repository_owner, autocomplete: :off
      field trusted_publisher_form, :text_field, :repository_name, autocomplete: :off
      field trusted_publisher_form, :text_field, :workflow_filename, autocomplete: :off
      field trusted_publisher_form, :text_field, :environment, autocomplete: :off, optional: true
      field trusted_publisher_form, :text_field, :workflow_repository_owner, autocomplete: :off, optional: true
      field trusted_publisher_form, :text_field, :workflow_repository_name, autocomplete: :off, optional: true
    end
  end

  private

  def field(form, type, name, optional: false, **)
    div class: "py-4" do
      form.label name, class: label_class do
        plain form.object.class.human_attribute_name(name)
        span(class: "t-text--s") { " (#{t('form.optional')})" } if optional
      end
      form.send(type, name, class: class_names(field_class, "border border-red-500" => form.object.errors.include?(name)), **)
      p(class: note_class) { t("oidc.trusted_publisher.github_actions.#{name}_help_html") }
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

  def note_class
    "mt-1 text-b4 text-neutral-600 dark:text-neutral-400 " \
      "[&_a]:text-orange-700 [&_a]:underline dark:[&_a]:text-orange-400"
  end
end
