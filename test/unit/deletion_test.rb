require 'test_helper'

class DeletionTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false # Disabled to test after_commit

  should belong_to :user

  setup do
    @user = create(:user)
    Pusher.new(@user, gem_file).process
    @version = Version.last
  end

  should "must be indexed" do
    @version.indexed = false
    assert Deletion.new(version: @version, user: @user).invalid?,
      "Deletion should only work on indexed gems"
  end

  should "unindexes" do
    delete_gem
    assert !@version.indexed?
  end

  should "be considered deleted" do
    delete_gem
    assert Version.yanked.include?(@version)
  end

  should "no longer be latest" do
    delete_gem
    assert !@version.reload.latest?
  end

  should "record version metadata" do
    deletion = Deletion.new(version: @version, user: @user)
    assert_nil deletion.rubygem
    deletion.valid?
    assert_equal deletion.rubygem, @version.rubygem.name
  end

  should "not appear in the version list" do
    delete_gem
    assert !Redis.current.exists(Rubygem.versions_key(@version.rubygem.name)),
      "Version still in list!"
  end

  should "delete the .gem file" do
    delete_gem
    assert_nil RubygemFs.instance.get("gems/#{@version.full_name}.gem"), "Rubygem still exists!"
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
