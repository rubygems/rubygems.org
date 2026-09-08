# frozen_string_literal: true

class OIDC::PendingTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag

  prop :pending_trusted_publisher, reader: :public

  def view_template
    self.title = t(".title")
    content_for(:subject) { raw(subject_sidebar) } # rubocop:disable Rails/OutputSafety -- trusted Rails partial

    h1(class: "text-h2 mb-10") { t(".title") }

    render CardComponent.new do
      form_with(model: pending_trusted_publisher, url: profile_oidc_pending_trusted_publishers_path) do |form|
        rubygem_name_field(form)
        organization_field(form)
        trusted_publisher_type_field(form)
        render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(github_action_form: form)
        render ButtonComponent.new do
          form.submit
        end
      end
    end
  end

  private

  def rubygem_name_field(form)
    div class: "py-4" do
      form.label :rubygem_name, class: label_class
      form.text_field :rubygem_name, class: field_class, autocomplete: :off
      p(class: note_class) { t("oidc.trusted_publisher.pending.rubygem_name_help_html") }
    end
  end

  def organization_field(form)
    organizations = current_user.manageable_organizations
    return if organizations.none?

    div class: "py-4" do
      form.label :organization_id, t("oidc.trusted_publisher.pending.organization_scope"), class: label_class
      form.collection_select :organization_id, organizations, :id, :name,
        { include_blank: t("api_keys.no_organization") }, class: field_class
      p(class: note_class) { t("oidc.trusted_publisher.pending.organization_scope_info") }
    end
  end

  def trusted_publisher_type_field(form)
    div class: "py-4" do
      form.label :trusted_publisher_type, class: label_class
      form.select :trusted_publisher_type,
        OIDC::TrustedPublisher.all.map { |type| [type.publisher_name, type.polymorphic_name] },
        {},
        class: field_class
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

  def subject_sidebar
    view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :settings })
  end
end
