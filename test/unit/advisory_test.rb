require 'test_helper'

class AdvisoryTest < ActiveSupport::TestCase
  should belong_to :version
  should belong_to :user
  should_not allow_value("invalid-url").for(:url)

  context "#create" do
    setup do
      @advisory = build(:advisory)
    end

    should "be valid with factory" do
      assert @advisory.valid?
    end

    context "for duplicate CVE" do
      setup do
        @advisory.save
        @invalid_advisory = build(:advisory, cve: @advisory.cve, version: @advisory.version)
        @valid_advisory = build(:advisory, cve: @advisory.cve)
      end

      should "not allow duplicate cve for same version" do
        refute @invalid_advisory.valid?
      end

      should "allow duplicate cve for different version" do
        assert @valid_advisory.valid?
      end
    end
  end
end
