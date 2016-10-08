require 'test_helper'

class DeletionTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false # Disabled to test after_commit

  should belong_to :user

  setup do
    @user = create(:user)
    Pusher.new(@user, gem_file).process
    @version = Version.last
    Rubygem.__elasticsearch__.create_index! force: true
    Rubygem.import
  end

  should "be indexed" do
    @version.indexed = false
    assert Deletion.new(version: @version, user: @user).invalid?,
      "Deletion should only work on indexed gems"
  end

  context "with deleted gem" do
    setup do
      Rails.cache.stubs(:delete)
      Fastly.stubs(:purge)
      delete_gem
      @gem_name = @version.rubygem.name
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

    should "set the yanked info checksum" do
      refute_nil @version.reload.yanked_info_checksum
    end

    should "delete the .gem file" do
      assert_nil RubygemFs.instance.get("gems/#{@version.full_name}.gem"), "Rubygem still exists!"
    end

    should "expire API memcached" do
      assert_received(Rails.cache, :delete) { |cache| cache.with("info/#{@gem_name}").twice }
      assert_received(Rails.cache, :delete) { |cache| cache.with("deps/v1/#{@gem_name}") }
      assert_received(Rails.cache, :delete) { |cache| cache.with("versions") }
      assert_received(Rails.cache, :delete) { |cache| cache.with("names") }
    end

    should "purge cdn cache" do
      Delayed::Worker.new.work_off
      assert_received(Fastly, :purge) { |path| path.with("info/#{@gem_name}").twice }
      assert_received(Fastly, :purge) { |path| path.with("versions").twice }
      assert_received(Fastly, :purge) { |path| path.with("names").twice }
    end
  end

  should "enque job for updating ES index, spec index and purging cdn" do
    assert_difference 'Delayed::Job.count', 8 do
      delete_gem
    end

    Delayed::Worker.new.work_off

    response = Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
                                                    type: 'rubygem',
                                                    id: @version.rubygem_id
    assert_equal true, response['_source']['yanked']
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
    [Rubygem, Version, User, Deletion, Delayed::Job, GemDownload].each(&:delete_all)
  end

  private

  def delete_gem
    Deletion.create!(version: @version, user: @user)
  end
end
