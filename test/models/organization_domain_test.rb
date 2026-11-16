# frozen_string_literal: true

require "test_helper"

class OrganizationDomainTest < ActiveSupport::TestCase
  setup { @organization = create(:organization) }

  def build_domain(domain, organization: @organization)
    OrganizationDomain.new(organization: organization, domain: domain)
  end

  def domain_events(tag)
    @organization.events.where(tag:)
  end

  context "domain limit" do
    setup do
      OrganizationDomain::LIMIT.pred.times { |i| create(:organization_domain, organization: @organization, domain: "d#{i}.example.com") }
    end

    should "allow the last domain up to the limit" do
      record = OrganizationDomain.add(organization: @organization, domain: "last.example.com")

      assert_predicate record, :persisted?
    end

    should "reject a domain past the limit with a base error and no event" do
      OrganizationDomain.add(organization: @organization, domain: "last.example.com")
      events = domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count

      record = OrganizationDomain.add(organization: @organization, domain: "extra.example.com")

      refute_predicate record, :persisted?
      assert_equal [:limit_reached], record.errors.details[:base].pluck(:error)
      assert_equal ["Organizations can have at most 5 domains. Delete one to add another."], record.errors.full_messages
      assert_equal events, domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count
      assert_equal OrganizationDomain::LIMIT, @organization.domains.count
    end

    should "allow adding again after a delete" do
      last = OrganizationDomain.add(organization: @organization, domain: "last.example.com")
      last.destroy_with_audit!(actor: create(:user))

      assert_predicate OrganizationDomain.add(organization: @organization, domain: "again.example.com"), :persisted?
    end

    should "not count another organization's domains" do
      create(:organization_domain, organization: @organization, domain: "last.example.com")
      other = create(:organization)

      assert_predicate OrganizationDomain.add(organization: other, domain: "mine.example.com"), :persisted?
    end
  end

  context "accepted domains" do
    {
      "example.com" => "example.com",
      "Example.COM" => "example.com",
      "  example.com  " => "example.com",
      "docs.example.com" => "docs.example.com",
      "example.co.uk" => "example.co.uk",
      "xn--bcher-kva.com" => "xn--bcher-kva.com"
    }.each do |input, stored|
      should "store #{input.inspect} as #{stored}" do
        record = build_domain(input)

        assert_predicate record, :valid?, record.errors.full_messages.to_sentence
        record.save!

        assert_equal stored, record.reload.domain
      end
    end
  end

  context "rejected domains" do
    expected_message = "Domain is invalid. The domain is expected in an example.com or docs.example.com format."

    {
      blank: [nil, "", "   "],
      invalid_characters: ["exa_mple.com", "exa mple.com", "exämple.com", "ｅｘａｍｐｌｅ.com", "\"example.com\"",
                           "example.com/path", "https://example.com", "user@example.com", "example.com:443", "*.example.com"],
      invalid_label: ["-example.com", "example-.com", "a..b.com", ".example.com", "example.com.", "#{'a' * 64}.com"],
      ip_address: %w[127.0.0.1 10.0.0.1],
      public_suffix: %w[co.uk github.io example.notarealtld],
      too_long: ["#{(['a' * 60] * 4).join('.')}.com"]
    }.each do |rule, inputs|
      inputs.each do |input|
        should "reject #{input.inspect} for #{rule} with the single format message and save nothing" do
          record = build_domain(input)

          refute_predicate record, :valid?
          assert_equal [error: :invalid_format, rules: [rule]], record.errors.details[:domain]
          assert_equal [expected_message], record.errors.full_messages
          assert_no_difference "OrganizationDomain.count" do
            refute record.save
          end
        end
      end
    end

    should "report a single label as both invalid_label and single_label behind one message" do
      %w[localhost com].each do |input|
        assert_equal %i[invalid_label single_label], OrganizationDomain::Name.errors_for(input), input
        record = build_domain(input)

        refute_predicate record, :valid?, input
        assert_equal [error: :invalid_format, rules: %i[invalid_label single_label]], record.errors.details[:domain], input
        assert_equal [expected_message], record.errors.full_messages, input
      end
    end

    should "collect every rule the domain breaks behind one message" do
      {
        "-bad_.com" => %i[invalid_characters invalid_label],
        "exa_mple..com" => %i[invalid_characters invalid_label],
        "#{(['a_' * 30] * 4).join('.')}.com" => %i[invalid_characters too_long],
        "-#{'a' * 63}.#{(['a' * 60] * 3).join('.')}.com" => %i[invalid_label too_long]
      }.each do |input, rules|
        record = build_domain(input)

        refute_predicate record, :valid?, input
        assert_equal [error: :invalid_format, rules:], record.errors.details[:domain], input
        assert_equal [expected_message], record.errors.full_messages, input
      end
    end

    should "not add a public suffix rule on top of a structural one" do
      ["https://example.com", "exa_mple.com", "-example.com", "localhost", "10.0.0.1"].each do |input|
        record = build_domain(input)
        record.valid?

        refute_includes record.errors.details[:domain].first[:rules], :public_suffix, input
      end
    end

    should "not include hints, offending characters or backticks in the message" do
      %w[https://example.com user@example.com *.example.com example.com:443 exämple.com exa_mple.com].each do |input|
        record = build_domain(input)
        record.valid?
        message = record.errors.full_messages.join

        refute_includes message, "`", input
        refute_match(/without https|email address|Wildcards|port|punycode|invalid characters|“/, message, input)
      end
    end

    should "have no per-rule messages or hints left in the locale" do
      %w[hints attributes.domain.invalid_characters attributes.domain.invalid_label attributes.domain.single_label
         attributes.domain.ip_address attributes.domain.public_suffix attributes.domain.too_long].each do |key|
        refute I18n.exists?("activerecord.errors.models.organization_domain.#{key}", :en), key
      end
    end

    should "not alter input beyond strip and downcase" do
      record = build_domain("https://Example.com")

      refute record.save
      assert_equal "https://example.com", record.domain
      assert_nil OrganizationDomain.find_by(domain: "example.com")
    end
  end

  context "domain constraints" do
    should "reject non-lowercase domains at the database" do
      record = create(:organization_domain, domain: "example.com")

      assert_raises(ActiveRecord::StatementInvalid) { OrganizationDomain.where(id: record.id).update_all(domain: "Example.com") }
    end

    should "reject non-lowercase domains in raw SQL" do
      assert_raises(ActiveRecord::StatementInvalid) do
        OrganizationDomain.connection.execute(<<~SQL.squish)
          INSERT INTO organization_domains (organization_id, domain, token, created_at, updated_at)
          VALUES (#{@organization.id}, 'Example.com', 'tok', now(), now())
        SQL
      end
    end

    should "not allow domain to change after create" do
      record = create(:organization_domain, domain: "example.com")

      assert_raises(ActiveRecord::ReadonlyAttributeError) { record.update(domain: "other.com") }
      assert_equal "example.com", record.reload.domain
    end

    should "allow the same pending domain for two organizations with different tokens" do
      first = create(:organization_domain, domain: "example.com")
      second = create(:organization_domain, domain: "example.com", organization: create(:organization))

      refute_equal first.token, second.token
    end

    should "not allow the same domain verified for two organizations" do
      create(:organization_domain, :verified, domain: "example.com")
      other = create(:organization_domain, domain: "example.com", organization: create(:organization))

      assert_raises(ActiveRecord::RecordNotUnique) { other.update!(verified_at: Time.zone.now) }
    end

    should "not allow the same domain active twice in one organization, regardless of case" do
      create(:organization_domain, domain: "example.com", organization: @organization)
      duplicate = build_domain("Example.com")

      refute_predicate duplicate, :valid?
      assert_equal [:taken], duplicate.errors.details[:domain].pluck(:error)
      assert_raises(ActiveRecord::RecordNotUnique) do
        OrganizationDomain.insert!({ organization_id: @organization.id, domain: "example.com", token: "other-token" })
      end
    end
  end

  context "token" do
    should "be generated on create, 256 bits and url-safe" do
      record = create(:organization_domain)

      assert_match(/\A[A-Za-z0-9_-]{43}\z/, record.token)
      assert_equal 32, Base64.urlsafe_decode64(record.token).bytesize
    end

    should "ignore a token passed through mass assignment" do
      record = OrganizationDomain.create!(organization: @organization, domain: "example.com", token: "attacker-chosen")

      refute_equal "attacker-chosen", record.token
    end

    should "not change after create" do
      record = create(:organization_domain)
      original = record.token

      assert_raises(ActiveRecord::ReadonlyAttributeError) { record.update(token: "other") }
      assert_equal original, record.reload.token
    end

    should "be unique at the database" do
      first = create(:organization_domain)

      assert_raises(ActiveRecord::RecordNotUnique) do
        OrganizationDomain.insert!({ organization_id: @organization.id, domain: "other.example.com", token: first.token })
      end
    end

    should "retry with a fresh token on a duplicate token" do
      existing = create(:organization_domain)
      fresh = "fresh-token"
      SecureRandom.stubs(:urlsafe_base64).with(32).returns(existing.token, fresh)

      record = OrganizationDomain.add(organization: @organization, domain: "other.example.com")

      assert_predicate record, :persisted?
      assert_equal fresh, record.reload.token
      assert_equal 1, domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count
    end

    should "give up after bounded retries" do
      existing = create(:organization_domain)
      SecureRandom.stubs(:urlsafe_base64).with(32).returns(existing.token)

      assert_no_difference ["OrganizationDomain.count", "Events::OrganizationEvent.count"] do
        assert_raises(ActiveRecord::RecordNotUnique) { OrganizationDomain.add(organization: @organization, domain: "other.example.com") }
      end
    end

    should "report a lost add race as a taken error instead of raising" do
      create(:organization_domain, domain: "example.com", organization: @organization)
      # Simulate the race: the uniqueness pre-check passed before the competing row committed.
      ActiveRecord::Validations::UniquenessValidator.any_instance.stubs(:validate_each)

      assert_no_difference ["OrganizationDomain.count", "Events::OrganizationEvent.count"] do
        record = OrganizationDomain.add(organization: @organization, domain: "example.com")

        refute_predicate record, :persisted?
        assert_equal [:taken], record.errors.details[:domain].pluck(:error)
      end
    end

    should "return the record with errors for an invalid domain" do
      assert_no_difference ["OrganizationDomain.count", "Events::OrganizationEvent.count"] do
        record = OrganizationDomain.add(organization: @organization, domain: "https://bad")

        refute_predicate record, :persisted?
        assert_equal [:invalid_format], record.errors.details[:domain].pluck(:error)
      end
    end

    should "return the persisted record and record exactly one added event" do
      record = OrganizationDomain.add(organization: @organization, domain: " Example.COM ")

      assert_predicate record, :persisted?
      assert_equal "example.com", record.domain
      assert_equal 1, domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count
    end

    should "not override any ActiveRecord internals" do
      refute_includes OrganizationDomain.private_instance_methods(false), :_create_record
      refute_includes OrganizationDomain.instance_methods(false), :_create_record
    end

    should "differ when a deleted domain is re-added, with the old row gone" do
      old = create(:organization_domain, domain: "example.com", organization: @organization)
      old.destroy_with_audit!(actor: create(:user))
      new_row = create(:organization_domain, domain: "example.com", organization: @organization)

      refute_equal old.token, new_row.token
      refute OrganizationDomain.exists?(old.id)
    end
  end

  context "txt record" do
    should "use the documented name and value without the organization" do
      record = create(:organization_domain, domain: "docs.example.com")

      assert_equal "_rubygems-challenge.docs.example.com", record.txt_record_name
      assert_equal "rubygems-verification=#{record.token}", record.txt_record_value
      assert_equal "rubygems-verification=", OrganizationDomain::TXT_VALUE_PREFIX
      refute_includes record.txt_record_name, @organization.handle
      refute_includes record.txt_record_value, @organization.handle
    end
  end

  context "checking" do
    should "be checking only while check_queued_at is fresh" do
      record = create(:organization_domain)

      refute_predicate record, :checking?
      record.update!(check_queued_at: Time.current)

      assert_predicate record, :checking?
      assert_includes OrganizationDomain.checking, record
      travel_to (OrganizationDomain::STALE_CHECK_AFTER + 1.minute).from_now do
        refute_predicate record, :checking?
        refute_includes OrganizationDomain.checking, record
        assert_includes OrganizationDomain.not_checking, record
      end
    end
  end

  context "verification state" do
    should "scope verified and pending" do
      verified = create(:organization_domain, :verified)
      pending = create(:organization_domain)

      assert_equal [verified], OrganizationDomain.verified.to_a
      assert_equal [pending], OrganizationDomain.pending.to_a
      assert_predicate verified, :verified?
      refute_predicate pending, :verified?
    end

    should "delete the row and its checks" do
      record = create(:organization_domain, :verified)
      create(:organization_domain_check, organization_domain: record)

      assert_difference ["OrganizationDomain.count", "OrganizationDomainCheck.count"], -1 do
        record.destroy_with_audit!(actor: create(:user))
      end
      refute OrganizationDomain.exists?(record.id)
      assert_empty @organization.domains.where(id: record.id)
    end

    should "free a verified domain for another organization after deletion" do
      record = create(:organization_domain, :verified, domain: "example.com")
      record.destroy_with_audit!(actor: create(:user))

      assert_nothing_raised do
        create(:organization_domain, :verified, domain: "example.com", organization: create(:organization))
      end
    end

    should "order checks newest first" do
      record = create(:organization_domain)
      old = create(:organization_domain_check, organization_domain: record, checked_at: 2.days.ago)
      recent = create(:organization_domain_check, organization_domain: record, checked_at: 1.day.ago)

      assert_equal [recent, old], record.checks.to_a
    end
  end

  context "organization events" do
    setup do
      @actor = create(:user)
      Current.user = @actor
    end

    teardown { Current.user = nil }

    should "record exactly one added event with domain and actor" do
      record = nil
      assert_difference -> { domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count }, 1 do
        record = OrganizationDomain.add(organization: @organization, domain: "Example.com")
      end

      additional = domain_events(Events::OrganizationEvent::DOMAIN_ADDED).sole.additional

      assert_equal "example.com", additional.domain
      assert_equal record.txt_record_value, additional.txt_record_value
      assert_equal @actor.to_gid, additional.actor_gid
    end

    should "record one added event when the token insert is retried" do
      existing = create(:organization_domain)
      SecureRandom.stubs(:urlsafe_base64).with(32).returns(existing.token, "fresh-token")

      assert_difference -> { domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count }, 1 do
        OrganizationDomain.add(organization: @organization, domain: "other.example.com")
      end
    end

    should "record no added event for a rejected add" do
      assert_no_difference -> { @organization.events.count } do
        refute_predicate OrganizationDomain.add(organization: @organization, domain: "localhost"), :persisted?
      end
    end

    should "record no added event for a lost add race" do
      create(:organization_domain, domain: "example.com", organization: @organization)
      ActiveRecord::Validations::UniquenessValidator.any_instance.stubs(:validate_each)

      assert_no_difference -> { domain_events(Events::OrganizationEvent::DOMAIN_ADDED).count } do
        refute_predicate OrganizationDomain.add(organization: @organization, domain: "example.com"), :persisted?
      end
    end

    should "record a deleted event with domain and actor" do
      record = create(:organization_domain, domain: "example.com", organization: @organization)
      deleter = create(:user)

      value = record.txt_record_value
      record.destroy_with_audit!(actor: deleter)

      refute OrganizationDomain.exists?(record.id)
      additional = domain_events(Events::OrganizationEvent::DOMAIN_DELETED).sole.additional

      assert_equal "example.com", additional.domain
      assert_equal value, additional.txt_record_value
      assert_equal deleter.to_gid, additional.actor_gid
    end

    should "raise and record one deleted event when a stale instance deletes it again" do
      first = OrganizationDomain.find(create(:organization_domain, organization: @organization).id)
      second = OrganizationDomain.find(first.id)

      first.destroy_with_audit!(actor: @actor)

      assert_raises(ActiveRecord::RecordNotFound) { second.destroy_with_audit!(actor: @actor) }
      assert_equal 1, domain_events(Events::OrganizationEvent::DOMAIN_DELETED).count
    end

    should "record no deleted event and keep the row when the delete fails" do
      record = create(:organization_domain, organization: @organization)
      record.stubs(:destroy!).raises(ActiveRecord::RecordNotDestroyed)

      assert_no_difference -> { domain_events(Events::OrganizationEvent::DOMAIN_DELETED).count } do
        assert_raises(ActiveRecord::RecordNotDestroyed) { record.destroy_with_audit!(actor: @actor) }
      end
      assert OrganizationDomain.exists?(record.id)
    end
  end
end
