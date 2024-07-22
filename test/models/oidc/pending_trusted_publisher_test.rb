require "test_helper"

class OIDC::PendingTrustedPublisherTest < ActiveSupport::TestCase
  setup do
    @pending_trusted_publisher = build(:oidc_pending_trusted_publisher)
  end
  subject { @pending_trusted_publisher }

  should belong_to(:trusted_publisher)
  should belong_to(:user)

  should validate_presence_of(:rubygem_name)
  should validate_uniqueness_of(:rubygem_name).scoped_to(:trusted_publisher_id, :trusted_publisher_type).case_insensitive

  test "validates rubygem name is available" do
    publisher = build(:oidc_pending_trusted_publisher, rubygem_name: "foo")

    assert_predicate publisher, :valid?

    rubygem = create(:rubygem, name: "foo")

    assert_predicate publisher, :valid?

    create(:version, rubygem: rubygem)

    refute_predicate publisher, :valid?
    assert_equal ["is already in use"], publisher.errors[:rubygem_name]
  end
end
