require "test_helper"

class OIDC::RubygemTrustedPublisherTest < ActiveSupport::TestCase
  setup do
    @rubygem_trusted_publisher = build(:oidc_rubygem_trusted_publisher)
  end
  subject { @rubygem_trusted_publisher }

  should belong_to(:rubygem)
  should belong_to(:trusted_publisher)

  should validate_uniqueness_of(:rubygem).scoped_to(:trusted_publisher_id, :trusted_publisher_type)
end
