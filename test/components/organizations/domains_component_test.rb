# frozen_string_literal: true

require "test_helper"

class Organizations::DomainsComponentTest < ComponentTest
  setup do
    @organization = create(:organization)
  end

  context "with no domains" do
    should "render the add form and no list" do
      render_component

      assert_selector "[data-testid='organization-domains']"
      assert_selector "form[action='/organizations/#{@organization.handle}/domains'][method='post'][data-testid='organization-domain-form']"
      assert_selector "input[name='organization_domain[domain]'][data-testid='organization-domain-input'][required]"
      assert_selector "button[data-testid='organization-domain-add']", text: "Add domain"
      assert_no_selector "[data-testid='organization-domain']"
      assert_no_selector "[data-testid='organization-domain-errors']"
    end
  end

  context "with a pending domain" do
    setup do
      @domain = create(:organization_domain, organization: @organization)
    end

    should "show Pending with a Verify button and the TXT record" do
      render_component(domains: [@domain])

      assert_selector "[data-testid='organization-domain'][data-domain='#{@domain.domain}']"
      assert_selector "[data-testid='organization-domain-status'][data-status='pending']", text: "Pending"
      assert_selector "button[data-testid='organization-domain-verify']", text: "Verify", exact_text: true
      assert_no_selector "[data-testid='organization-domain-retry']"
      assert_no_selector "[data-testid='organization-domain-verified-at']"
      assert_no_selector "[data-testid='organization-domain-failure']"
      assert_selector "[data-testid='organization-domain-txt-name'] input[value='#{@domain.txt_record_name}']"
      assert_selector "[data-testid='organization-domain-txt-value'] input[value='#{@domain.txt_record_value}']"
      assert_text "Publish this TXT record"
    end

    should "render the delete button with its confirm text" do
      render_component(domains: [@domain])

      assert_selector "[data-testid='organization-domain-delete']", text: "Delete"
      form = page.find("[data-testid='organization-domain-delete']").find(:xpath, "ancestor::form")

      assert_equal "delete", form.find_field("_method", type: :hidden).value
      assert_includes form["data-turbo-confirm"], "Delete #{@domain.domain}?"
      assert_equal "/organizations/#{@organization.handle}/domains/#{@domain.id}", form["action"]
    end
  end

  context "with a verified domain" do
    setup do
      @domain = create(:organization_domain, :verified, organization: @organization)
    end

    should "show Verified, the verified time and only Delete" do
      render_component(domains: [@domain])

      assert_selector "[data-testid='organization-domain-status'][data-status='verified']", text: "Verified"
      assert_selector "[data-testid='organization-domain-verified-at']", text: "ago"
      assert_no_selector "[data-testid='organization-domain-verify']"
      assert_no_selector "[data-testid='organization-domain-retry']"
      assert_no_text "Verify again"
      assert_selector "button[data-testid='organization-domain-delete']", text: "Delete"
      assert_text "Keep this TXT record published."
    end
  end

  context "with the domain limit" do
    should "render the add form below the limit" do
      domains = create_list(:organization_domain, OrganizationDomain::LIMIT - 1, organization: @organization)
      render_component(domains:)

      assert_selector "[data-testid='organization-domain-form']"
      assert_no_selector "[data-testid='organization-domain-limit']"
    end

    should "replace the form with a note at the limit" do
      domains = create_list(:organization_domain, OrganizationDomain::LIMIT, organization: @organization)
      render_component(domains:)

      assert_no_selector "[data-testid='organization-domain-form']"
      assert_selector "[data-testid='organization-domain-limit']",
        text: "You've added the maximum of 5 domains. Delete one to add another."
      assert_selector "[data-testid='organization-domain']", count: OrganizationDomain::LIMIT
    end
  end

  context "with a checking domain" do
    setup do
      @domain = create(:organization_domain, organization: @organization, check_queued_at: Time.zone.now)
    end

    should "show Checking, the background note and neither Verify nor Retry" do
      render_component(domains: [@domain])

      assert_selector "[data-testid='organization-domain-status'][data-status='checking']", text: "Checking"
      assert_selector "[data-testid='organization-domain-checking']", text: "running in the background"
      assert_no_selector "[data-testid='organization-domain-verify']"
      assert_no_selector "[data-testid='organization-domain-retry']"
      assert_selector "[data-testid='organization-domain-delete']"
    end

    should "not show a failure box even if the latest check failed" do
      check = create(:organization_domain_check, :failure, organization_domain: @domain)
      render_component(domains: [@domain], latest_checks: { @domain.id => check })

      assert_no_selector "[data-testid='organization-domain-failure']"
      assert_selector "[data-status='checking']"
    end
  end

  context "with a failed domain" do
    setup do
      @domain = create(:organization_domain, organization: @organization)
    end

    {
      "record_not_found" => "We couldn't find a TXT record at",
      "record_mismatch" => "doesn't match the value shown below",
      "other_error" => "We couldn't complete the DNS lookup for"
    }.each do |outcome, message|
      should "show the #{outcome} message above the row with Retry" do
        check = create(:organization_domain_check, :failure, organization_domain: @domain, outcome: outcome)
        render_component(domains: [@domain], latest_checks: { @domain.id => check })

        assert_selector "[data-testid='organization-domain-status'][data-status='failed']", text: "Failed"
        assert_selector "[data-testid='organization-domain-failure'][data-outcome='#{outcome}']"
        assert_selector "[data-testid='organization-domain-failure-detail']", text: message
        assert_selector "[data-testid='organization-domain-failure-detail']", text: @domain.txt_record_name
        assert_selector "[data-testid='organization-domain-checked-at']", text: "ago"
        assert_selector "button[data-testid='organization-domain-retry']", text: "Retry"
        assert_no_selector "[data-testid='organization-domain-verify']"
      end
    end

    should "render the failure box before the domain row header" do
      check = create(:organization_domain_check, :failure, organization_domain: @domain)
      render_component(domains: [@domain], latest_checks: { @domain.id => check })

      assert_selector "[data-testid='organization-domain-failure'] + div [data-testid='organization-domain-status']"
    end

    should "never render the stored check message" do
      check = create(:organization_domain_check, :failure, organization_domain: @domain, message: "SECRET internal resolver detail")
      render_component(domains: [@domain], latest_checks: { @domain.id => check })

      assert_no_text "SECRET internal resolver detail"
    end

    should "stay pending when the latest check succeeded" do
      check = create(:organization_domain_check, organization_domain: @domain)
      render_component(domains: [@domain], latest_checks: { @domain.id => check })

      assert_selector "[data-status='pending']"
      assert_no_selector "[data-testid='organization-domain-failure']"
    end
  end

  context "with validation errors" do
    should "list the errors and preserve the input" do
      new_domain = @organization.domains.build(domain: "bad domain")
      new_domain.validate
      render_component(new_domain:, domain_input: "bad domain")

      assert_selector "[data-testid='organization-domain-errors'] li", minimum: 1
      assert_selector "input[data-testid='organization-domain-input'][value='bad domain'].border-red-500"
    end
  end

  should "run no SQL when rendering preloaded props" do
    domain = create(:organization_domain, organization: @organization)
    check = create(:organization_domain_check, :failure, organization_domain: domain)
    verified = create(:organization_domain, :verified, organization: @organization)
    domains = @organization.domains.to_a
    component = Organizations::DomainsComponent.new(
      organization: @organization, domains:, latest_checks: { domain.id => check }
    )
    view_context

    assert_no_queries { render(component) }
    assert_selector "[data-domain='#{verified.domain}']"
  end

  private

  def render_component(domains: [], latest_checks: {}, **)
    render Organizations::DomainsComponent.new(organization: @organization, domains:, latest_checks:, **)
  end
end
