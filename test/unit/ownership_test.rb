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

    subject { @ownership }

    should_validate_uniqueness_of :user_id, :scoped_to => :rubygem_id

    should "not blow up if checking for upload dies" do
      WebMock.stub_request(:get, @url).
        to_return(:body   => "Nothing to be found 'round here", 
                  :status => 404)
      assert ! @ownership.migrated?
      assert ! @ownership.approved
    end

    should "approve upload" do
      WebMock.stub_request(:get, @url).to_return(:body => @ownership.token)

      assert @ownership.migrated?
      assert @ownership.approved
    end

    should "use gem name if rubyforge project doesn't exist" do
      @ownership.rubygem.versions.latest.update_attribute(:rubyforge_project, nil)

      gem_name = @ownership.rubygem.name
      WebMock.stub_request(:get, "http://#{gem_name}.rubyforge.org/migrate-#{gem_name}.html").
        to_return(:body => @ownership.token + "\n")

      assert @ownership.migrated?
      assert @ownership.approved
    end

    should "approve upload if token ends with a newline" do
      WebMock.stub_request(:get, @url).to_return(:body => @ownership.token + "\n")

      assert @ownership.migrated?
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

  context "with multiple ownerships on the same rubygem" do
    setup do
      @rubygem       = Factory(:rubygem)
      @ownership_one = Factory(:ownership, :rubygem => @rubygem)
      @ownership_two = Factory(:ownership, :rubygem => @rubygem)
    end

    should "allow deletion of one ownership" do
      @ownership_one.destroy
      assert_equal 1, @rubygem.owners.length
    end

    should "not allow deletion of both ownerships" do
      @ownership_one.destroy
      @ownership_two.destroy
      assert_equal 1, @rubygem.owners.length
      assert_equal "Can't delete last owner of a gem.", @ownership_two.errors.on(:base)
    end
  end

end
