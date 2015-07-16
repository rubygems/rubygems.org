require 'test_helper'

class DeletionTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false # Disabled to test after_commit

  def setup
    super

    @user = create(:user)
    Pusher.new(@user, gem_file).process
    @version = Version.last
  end

  test "must be indexed" do
    @version.indexed = false
    assert Deletion.new(version: @version, user: @user).invalid?, "Deletion should only work on indexed gems"
  end

  test "unindexes" do
    delete_gem
    assert !@version.indexed?
  end

  test "be considered deleted" do
    delete_gem
    assert Version.yanked.include?(@version)
  end

  test "no longer be latest" do
    delete_gem
    assert !@version.reload.latest?
  end

  test "not appear in the version list" do
    delete_gem
    assert !Redis.current.exists(Rubygem.versions_key(@version.rubygem.name)), "Version still in list!"
  end

  test "delete the .gem file" do
    delete_gem
    assert_nil RubygemFs.instance.get("gems/#{@version.full_name}.gem"), "Rubygem still exists!"
  end

  def teardown
    super
    [Rubygem, Version, User, Deletion].each(&:delete_all) # necessary thanks to after_commit not cleaning up for us
  end

  private

  def delete_gem
    Deletion.create!(version: @version, user: @user)
  end
end
