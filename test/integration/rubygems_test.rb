require "test_helper"

class RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    create_list(:rubygem, 20) # rubocop:disable FactoryBot/ExcessiveCreateList
    create(:rubygem, name: "arrakis", number: "1.0.0")
  end

  test "gems list shows pagination" do
    get "/gems"

    assert page.has_content? "arrakis"
  end

  test "gems list doesn't fall prey to path_params query param" do
    get "/gems?path_params=string"

    assert page.has_content? "arrakis"
  end

  test "GET to show for a gem published with an attestation" do
    rubygem = create(:rubygem, name: "attested", number: "1.0.0")
    trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: rubygem)
    create(:api_key, scopes: %i[push_rubygem], owner: trusted_publisher.trusted_publisher)
    create(:attestation, version: rubygem.versions.sole)

    get "/gems/attested"

    assert page.has_content? "Provenance"
  end

  test "GET to show for a fully yanked gem as owner" do
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    rubygem = create(:rubygem, owners: [user], number: "1.0.0", created_at: 2.months.ago)
    version = rubygem.versions.sole
    user.deletions.create!(version:)
    rubygem.reload

    assert_predicate rubygem.public_versions.to_a, :empty?

    get "/gems/#{rubygem.name}"

    assert page.has_content? "This gem previously existed, but has been removed by its owner."
    refute page.has_link? "Owners"
    refute page.has_link? "Trusted publishers"
    refute page.has_link? "Security Events"

    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get "/gems/#{rubygem.name}"

    assert page.has_link? "Owners"
    assert page.has_link? "Trusted publishers"
    assert page.has_link? "Security Events"
  end
end
