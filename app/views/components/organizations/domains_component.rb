# frozen_string_literal: true

class Organizations::DomainsComponent < ApplicationComponent
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::ButtonTo

  register_value_helper :time_ago_in_words

  prop :organization, reader: :private
  prop :domains, reader: :private
  prop :latest_checks, reader: :private
  prop :new_domain, default: nil, reader: :private
  prop :domain_input, default: nil, reader: :private

  INPUT_CLASSES = "w-full text-b2 rounded-lg dark:bg-neutral-950 focus:ring-inset focus:ring-1 focus:ring-orange-500"
  INPUT_ERROR_CLASSES = "border-red-500 dark:border-red-400"
  ACTION_CLASSES = "px-4 py-2 rounded border text-b3 cursor-pointer"
  VERIFY_CLASSES = "border-orange-500 text-orange-700 dark:text-orange-300 hover:bg-orange-50 dark:hover:bg-neutral-800"
  DELETE_CLASSES = "border-neutral-400 text-neutral-800 dark:text-neutral-200 hover:bg-neutral-100 dark:hover:bg-neutral-800"
  BADGE_CLASSES = {
    verified: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300",
    failed: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300",
    pending: "bg-neutral-100 text-neutral-800 dark:bg-neutral-800 dark:text-neutral-200",
    checking: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
  }.freeze

  def view_template
    div(class: "mt-10", data: { testid: "organization-domains" }) do
      render CardComponent.new do |c|
        c.head { c.title dt(:title), icon: "language" }
        p(class: "text-b3 text-neutral-600 dark:text-neutral-400 mb-6") { dt(:description) }
        limit_reached? ? limit_note : new_domain_form
        domain_list if domains.any?
      end
    end
  end

  private

  def limit_reached?
    domains.size >= OrganizationDomain::LIMIT
  end

  def limit_note
    form_errors
    p(class: "text-b3 text-neutral-800 dark:text-neutral-200", data: { testid: "organization-domain-limit" }) do
      dt(:limit_note, count: OrganizationDomain::LIMIT)
    end
  end

  def new_domain_form
    form_with url: organization_domains_path(organization), method: :post, scope: :organization_domain,
              data: { testid: "organization-domain-form" } do |form|
      form.label :domain, dt(:domain), class: "block text-b2 font-semibold mb-2"
      form_errors
      div(class: "flex flex-col sm:flex-row gap-4") do
        domain_field(form)
        render ButtonComponent.new(
          dt(:add),
          type: :submit,
          style: :outline,
          class: "shrink-0",
          data: { testid: "organization-domain-add" }
        )
      end
      p(class: "mt-2 text-b3 text-neutral-600 dark:text-neutral-400") { dt(:domain_hint) }
    end
  end

  def domain_field(form)
    form.text_field :domain,
      value: domain_input,
      class: classes(INPUT_CLASSES, (INPUT_ERROR_CLASSES if form_error_messages.any?)),
      placeholder: "example.com",
      required: true,
      autocomplete: "off",
      autocapitalize: "none",
      spellcheck: false,
      data: { testid: "organization-domain-input" }
  end

  def form_error_messages
    new_domain ? new_domain.errors.full_messages : []
  end

  def form_errors
    return if form_error_messages.empty?

    ul(class: "mb-2 list-disc pl-5 text-b3 text-red-700 dark:text-red-300", data: { testid: "organization-domain-errors" }) do
      form_error_messages.each { |message| li { message } }
    end
  end

  def domain_list
    ul(class: "mt-8 divide-y divide-neutral-200 dark:divide-neutral-800 border-t border-neutral-200 dark:border-neutral-800") do
      domains.each { |domain| domain_item(domain) }
    end
  end

  def domain_item(domain)
    check = latest_checks[domain.id]
    status = status_for(domain, check)

    li(class: "py-6", data: { testid: "organization-domain", domain: domain.domain }) do
      failure_box(domain, check) if status == :failed
      domain_header(domain, status)
      checking_note if status == :checking
      txt_record(domain)
    end
  end

  def failure_box(domain, check)
    div(
      class: "mb-4 p-4 rounded-md border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 " \
             "text-red-800 dark:text-red-200 space-y-2",
      data: { testid: "organization-domain-failure", outcome: check.outcome }
    ) do
      p(class: "text-b3 font-semibold", data: { testid: "organization-domain-failure-detail" }) { failure_message(domain, check) }
      p(class: "text-b3") { dt(:retry_hint) }
      p(class: "text-b4 text-red-700 dark:text-red-300") do
        plain "#{dt(:checked_at)} "
        time_element(check.checked_at, dt(:checked_ago, time: time_ago_in_words(check.checked_at)),
                     data: { testid: "organization-domain-checked-at" })
      end
    end
  end

  def domain_header(domain, status)
    div(class: "flex flex-wrap items-center justify-between gap-4") do
      div(class: "flex flex-wrap items-center gap-3 min-w-0") do
        span(class: "text-b1 font-semibold break-all") { domain.domain }
        status_badge(status)
        verified_at(domain) if domain.verified?
      end
      div(class: "flex items-center gap-3") do
        verify_button(domain, status)
        delete_button(domain)
      end
    end
  end

  def status_badge(status)
    span(class: "px-2 py-0.5 rounded-full text-b4 font-semibold #{BADGE_CLASSES.fetch(status)}",
         data: { testid: "organization-domain-status", status: }) do
      dt("status.#{status}")
    end
  end

  def verified_at(domain)
    time_element(domain.verified_at, dt(:verified_ago, time: time_ago_in_words(domain.verified_at)),
                 class: "text-b4 text-neutral-600 dark:text-neutral-400",
                 data: { testid: "organization-domain-verified-at" })
  end

  def time_element(time, text, **attributes)
    time(datetime: time.iso8601, title: time.utc.to_s, **attributes) { text }
  end

  def verify_button(domain, status)
    return if %i[checking verified].include?(status)

    button_to action_label(status), verify_organization_domain_path(organization, domain),
      method: :post,
      class: "#{ACTION_CLASSES} #{VERIFY_CLASSES}",
      data: { testid: action_testid(status), disable_with: t("form_disable_with") }
  end

  def delete_button(domain)
    button_to dt(:delete), organization_domain_path(organization, domain),
      method: :delete,
      class: "#{ACTION_CLASSES} #{DELETE_CLASSES}",
      form: { data: { turbo_confirm: dt(:confirm_delete, domain: domain.domain) } },
      data: { testid: "organization-domain-delete" }
  end

  def checking_note
    p(class: "mt-4 text-b3 text-neutral-600 dark:text-neutral-400", data: { testid: "organization-domain-checking" }) do
      dt(:checking)
    end
  end

  def txt_record(domain)
    div(class: "mt-4 space-y-2") do
      p(class: "text-b3 text-neutral-600 dark:text-neutral-400") { dt(domain.verified? ? :keep_published : :publish) }
      div(data: { testid: "organization-domain-txt-name" }) do
        render CopyFieldComponent.new(value: domain.txt_record_name, label: dt(:txt_name), name: "txt_name_#{domain.id}")
      end
      div(data: { testid: "organization-domain-txt-value" }) do
        render CopyFieldComponent.new(value: domain.txt_record_value, label: dt(:txt_value), name: "txt_value_#{domain.id}")
      end
    end
  end

  def status_for(domain, check)
    if domain.checking?
      :checking
    elsif domain.verified?
      :verified
    elsif check&.failure?
      :failed
    else
      :pending
    end
  end

  def action_label(status)
    status == :failed ? dt(:retry) : dt(:verify)
  end

  def action_testid(status)
    status == :failed ? "organization-domain-retry" : "organization-domain-verify"
  end

  def failure_message(domain, check)
    dt("failure.#{check.outcome}", name: domain.txt_record_name)
  end

  def dt(key, **)
    t("organizations.domains.#{key}", **)
  end
end
