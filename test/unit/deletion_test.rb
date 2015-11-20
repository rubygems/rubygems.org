require 'test_helper'

class DeletionTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false # Disabled to test after_commit

  should belong_to :user

  setup do
    @user = create(:user)
    Pusher.new(@user, gem_file).process
    @version = Version.last
  end

  should "be indexed" do
    @version.indexed = false
    assert Deletion.new(version: @version, user: @user).invalid?,
      "Deletion should only work on indexed gems"
  end

  context "with deleted gem" do
    setup do
      delete_gem
    end

    should "unindexes" do
      refute @version.indexed?
    end

    should "be considered deleted" do
      assert Version.yanked.include?(@version)
    end

    should "no longer be latest" do
      refute @version.reload.latest?
    end

    should "keep the yanked time" do
      assert @version.reload.yanked_at
    end

    should "delete the .gem file" do
      assert_nil RubygemFs.instance.get("gems/#{@version.full_name}.gem"), "Rubygem still exists!"
    end
  end

  should "record version metadata" do
    deletion = Deletion.new(version: @version, user: @user)
    assert_nil deletion.rubygem
    deletion.valid?
    assert_equal deletion.rubygem, @version.rubygem.name
  end

  test "expire API memcached" do
    Rails.cache.write("deps/v1/#{@version.rubygem.name}", "omg!")
    refute_nil Rails.cache.fetch("deps/v1/#{@version.rubygem.name}")

    delete_gem

    assert_nil Rails.cache.fetch("deps/v1/#{@version.rubygem.name}")
  end

  teardown do
    # This is necessary due to after_commit not cleaning up for us
    [Rubygem, Version, User, Deletion].each(&:delete_all)
  end

  private

  def delete_gem
    Deletion.create!(version: @version, user: @user)
  end
end
