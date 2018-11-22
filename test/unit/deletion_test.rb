require 'test_helper'

class DeletionTest < ActiveSupport::TestCase
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
      GemCachePurger.stubs(:call)
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

    should "call GemCachePurger" do
      assert_received(GemCachePurger, :call) { |obj| obj.with(@gem_name).once }
    end
  end

  should "enque job for updating ES index, spec index and purging cdn" do
    assert_difference 'Delayed::Job.count', 7 do
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

  context "with restored gem" do
    setup do
      GemCachePurger.stubs(:call)
      Fastly.stubs(:purge)
      RubygemFs.instance.stubs(:restore).returns true
      @deletion = delete_gem
      @deletion.restore!
      @gem_name = @version.rubygem.name
    end

    should "index version" do
      assert @version.indexed?
    end

    should "reorder versions" do
      assert @version.reload.latest?
    end

    should "remove the yanked time and yanked_info_checksum" do
      assert_nil @version.yanked_at
      assert_nil @version.yanked_info_checksum
    end

    should "call GemCachePurger" do
      assert_received(GemCachePurger, :call) { |subject| subject.with(@gem_name).twice }
    end

    should "purge fastly" do
      Delayed::Worker.new.work_off

      assert_received(Fastly, :purge) do |subject|
        subject.with("gems/#{@version.full_name}.gem").twice
      end
      assert_received(Fastly, :purge) do |subject|
        subject.with("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz").twice
      end
    end

    should "remove deletion record" do
      assert @deletion.destroyed?
    end
  end

  private

  def delete_gem
    Deletion.create!(version: @version, user: @user)
  end
end
