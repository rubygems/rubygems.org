# frozen_string_literal: true

class OIDC::PendingTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag

  prop :pending_trusted_publisher, reader: :public
  prop :trusted_publisher_types, reader: :private
  prop :selected_trusted_publisher_type, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize
    self.title = t(".title")
    content_for(:subject) { raw(subject_sidebar) } # rubocop:disable Rails/OutputSafety -- trusted Rails partial

    h1(class: "text-h2 mb-10") { t(".title") }

    form_with(url: new_profile_oidc_pending_trusted_publisher_path, method: :get, class: "mb-4") do |f|
      f.label :trusted_publisher_type, "Select CI/CD Provider:", class: label_class
      f.select :trusted_publisher_type, trusted_publisher_types.map { |type|
                                          [type.publisher_name, type.url_identifier]
                                        }, { selected: selected_trusted_publisher_type&.url_identifier }, class: field_class
      f.submit "Select", class: "inline-flex items-center justify-center rounded border-2 border-orange-600 " \
                                "text-orange-600 px-4 h-9 min-h-9 text-b3 hover:bg-orange-600/5 " \
                                "active:bg-orange-600/10 transition focus:outline-none mt-2"
    end

    return unless selected_trusted_publisher_type

    render CardComponent.new do
      form_with(
        model: pending_trusted_publisher,
        url: profile_oidc_pending_trusted_publishers_path
      ) do |f|
        div class: "py-4" do
          f.label :rubygem_name, class: label_class
          f.text_field :rubygem_name, class: field_class, autocomplete: :off
          p(class: note_class) { t("oidc.trusted_publisher.pending.rubygem_name_help_html") }
        end

        f.hidden_field :trusted_publisher_type, value: selected_trusted_publisher_type.polymorphic_name
        render selected_trusted_publisher_type.form_component.new(form: f)

        render ButtonComponent.new do
          f.submit
        end
      end
    end
  end

  private

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

  def subject_sidebar
    view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :settings })
  end
end
