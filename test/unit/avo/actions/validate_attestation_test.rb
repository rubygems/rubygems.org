require "test_helper"

class ValidateAttestationTest < ActiveSupport::TestCase
  setup do
    @view_context = mock
    @avo = mock
    @view_context.stubs(:avo).returns(@avo)
    @avo.stubs(:resources_audit_path).returns("resources_audit_path")
    Avo::Current.stubs(:view_context).returns(@view_context)
    @admin = create(:admin_github_user, :is_admin)
    @rubygem = create(:rubygem)
    @version = create(:version, rubygem: @rubygem)
  end

  test "fails when gem file not found" do
    attestation = create(:attestation, version: @version)

    RubygemFs.instance.stubs(:get).returns(nil)

    action = Avo::Actions::ValidateAttestation.new
    action.handle(
      fields: {},
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    assert_equal :error, action.response[:messages].first[:type]
    assert_includes action.response[:messages].first[:body], "Gem file not found"
  end

  test "fails when sigstore bundle is invalid" do
    attestation = Attestation.create!(
      version: @version,
      media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
      body: { "invalid" => "bundle" }
    )

    RubygemFs.instance.stubs(:get).returns("gem contents")

    action = Avo::Actions::ValidateAttestation.new
    action.handle(
      fields: {},
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    assert_equal :error, action.response[:messages].first[:type]
  end

  test "creates audit record on validation" do
    attestation = create(:attestation, version: @version)

    RubygemFs.instance.stubs(:get).returns(nil)

    action = Avo::Actions::ValidateAttestation.new
    action.handle(
      fields: {},
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    audit = Audit.last

    assert_equal "Validate attestation", audit.action
    assert_equal attestation.class.name, audit.auditable_type
    assert_equal attestation.id, audit.auditable_id
    assert_equal @admin.id, audit.admin_github_user_id
  end
end
