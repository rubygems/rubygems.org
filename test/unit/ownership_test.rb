require 'test_helper'

class OwnershipTest < ActiveSupport::TestCase

  should "be valid with factory" do
    assert_valid Factory.build(:ownership)
  end

  should_belong_to :rubygem
  should_have_db_index :rubygem_id
  should_belong_to :user
  should_have_db_index :user_id

  context "with ownership" do
    setup do
      @ownership = Factory(:ownership)
      Factory(:version, :rubygem => @ownership.rubygem)
      name = @ownership.rubygem.name
      subdomain = @ownership.rubygem.rubyforge_project
      @url = "http://#{subdomain}.rubyforge.org/migrate-#{name}.html"
    end

    should "not blow up if checking for upload dies" do
      FakeWeb.register_uri(:get, @url, :body   => "Nothing to be found 'round here",
                                       :status => ["404", "Not Found"])
      @ownership.check_for_upload
      assert ! @ownership.approved
    end

    should "check for upload" do
      FakeWeb.register_uri(:get, @url, :body => @ownership.token)

      @ownership.check_for_upload
      assert @ownership.approved
    end

    should "delete other ownerships once approved" do
      rubygem = @ownership.rubygem
      other_ownership = rubygem.ownerships.create(:user => Factory(:user))
      @ownership.update_attribute(:approved, true)

      assert Ownership.exists?(@ownership.id)
      assert ! Ownership.exists?(other_ownership.id)
    end

    should "create token" do
      assert_not_nil @ownership.token
    end
  end
end
