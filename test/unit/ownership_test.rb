require "test_helper"

class OwnershipTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert build(:ownership).valid?
  end

  should belong_to :rubygem
  should have_db_index :rubygem_id
  should belong_to :user
  should have_db_index :user_id
  should belong_to :authorizer

  context "with ownership" do
    setup do
      @ownership = create(:ownership)
      create(:version, rubygem: @ownership.rubygem)
    end

    subject { @ownership }

    should validate_uniqueness_of(:user_id).scoped_to(:rubygem_id)
  end

  context "by_indexed_gem_name" do
    setup do
      @ownership = create(:ownership)
      create_list(:version, 5, rubygem: @ownership.rubygem)
      @user = @ownership.user
    end

    should "return only one ownership" do
      assert_equal 1, @user.ownerships.by_indexed_gem_name.size
    end
  end

  context "by_indexed_gem_name order matters" do
    setup do
      @user = create(:user)
      @gems = %w[zork asf medium]
      @gems.each do |gem_name|
        created_gem = create(:rubygem, name: gem_name)
        create_list(:version, 3, rubygem: created_gem)
        create(:ownership, rubygem: created_gem, user: @user)
      end

      @ownerships = @user.ownerships.by_indexed_gem_name
    end

    should "ownerships should be sorted by rubygem name ascendant order" do
      assert_equal @gems.sort, (@ownerships.map { |own| own.rubygem.name })
    end
  end

  context "#destroy_and_notify" do
    setup do
      @rubygem       = create(:rubygem)
      @ownership_one = create(:ownership, rubygem: @rubygem)
      @ownership_two = create(:ownership, rubygem: @rubygem)
      @ownership_three = create(:ownership, :unconfirmed, rubygem: @rubygem)
    end

    should "allow deletion of one ownership" do
      @ownership_one.destroy_and_notify
      assert_equal 1, @rubygem.owners.length
      assert_equal 2, @rubygem.owners_including_unconfirmed.length
    end

    should "allow deletion of unconfirmed ownership" do
      @ownership_three.destroy_and_notify
      assert_equal 2, @rubygem.owners_including_unconfirmed.length
    end

    should "not allow deletion of both ownerships" do
      @ownership_one.destroy_and_notify
      @ownership_two.destroy_and_notify
      assert_equal 1, @rubygem.owners.length
      assert_equal @ownership_two.user, @rubygem.owners.last
    end
  end

  context "#create" do
    setup do
      @authorizer = create(:user)
      @new_owner = create(:user)
      @rubygem = create(:rubygem)
      @ownership = @rubygem.ownerships.create(user: @new_owner, authorizer: @authorizer)
    end
    should "create unconfirmed ownership" do
      assert_nil @ownership.confirmed_at
    end

    should "generate 20 char hex confirmation token" do
      assert_match(/[0-9a-f]{20}/, @ownership.token)
    end
  end

  context "#valid_confirmation_token?" do
    setup do
      @ownership = create(:ownership)
    end

    should "return false when email confirmation token has expired" do
      @ownership.update_attribute(:token_expires_at, 2.minutes.ago)
      refute @ownership.valid_confirmation_token?
    end

    should "return true when email confirmation token has not expired" do
      two_minutes_in_future = Time.zone.now + 2.minutes
      @ownership.update_attribute(:token_expires_at, two_minutes_in_future)
      assert @ownership.valid_confirmation_token?
    end
  end
end
