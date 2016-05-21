require 'test_helper'

class GemDownloadTest < ActiveSupport::TestCase
  setup do
    create(:gem_download, count: 0)
  end

  context "#increment" do
    should "not update if download doesnt exist" do
      assert_nil GemDownload.increment(1, rubygem_id: 1)
    end

    should "not update if download count is nil" do
      create(:gem_download, rubygem_id: 1, version_id: 0, count: nil)
      download = GemDownload.increment(1, rubygem_id: 1)
      assert_nil download.count
    end

    should "update the count" do
      create(:gem_download, rubygem_id: 1, version_id: 1, count: 0)
      GemDownload.increment(1, rubygem_id: 1, version_id: 1)

      assert_equal 1, GemDownload.where(rubygem_id: 1, version_id: 1).first.count
    end

    should "take optional count warg" do
      version = create(:version)
      rubygem = version.rubygem

      GemDownload.increment(100, rubygem_id: version.rubygem_id, version_id: version.id)
      GemDownload.increment(100, rubygem_id: version.rubygem_id)

      assert_equal 100, GemDownload.count_for_version(version.id)
      assert_equal 100, GemDownload.count_for_rubygem(rubygem.id)
    end
  end

  uses_transaction :test_update_the_count_atomically
  def test_update_the_count_atomically
    create(:gem_download, rubygem_id: 1, version_id: 1, count: 0)

    25.times do
      Array.new(4) do
        Thread.new { GemDownload.increment(1, rubygem_id: 1, version_id: 1) }
      end.each(&:join)
    end

    assert_equal 100, GemDownload.where(rubygem_id: 1, version_id: 1).first.count
  ensure
    GemDownload.delete_all
  end

  context "#bulk_update" do
    should "write the proper values" do
      versions = Array.new(2) { create(:version) }
      gems     = versions.map(&:rubygem)
      counts   = Array.new(2) { rand(100) }
      data     = versions.map.with_index { |v, i| [v.full_name, counts[i]] }

      GemDownload.bulk_update(data)

      2.times.each do |i|
        assert_equal counts[i], GemDownload.count_for_version(versions[i].id)
        assert_equal counts[i], GemDownload.count_for_rubygem(gems[i].id)
      end
    end
  end

  should "not count, wrong named versions" do
    GemDownload.bulk_update([['foonotexists', 100]])
    assert_equal 0, GemDownload.total_count

    version = create(:version)
    GemDownload.bulk_update([['foonotexists', 100], ['dddd', 50], [version.full_name, 2]])
    assert_equal 2, GemDownload.total_count
  end

  should "write global downloads count" do
    counts = Array.new(3) { [create(:version).full_name, 2] }
    GemDownload.bulk_update(counts)
    assert_equal 6, GemDownload.total_count
  end

  should "track platform gem downloads correctly" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem, platform: "mswin32-60")
    other_platform_version = create(:version, rubygem: rubygem, platform: "mswin32")

    GemDownload.bulk_update([[version.full_name, 1]])

    assert_equal 1, GemDownload.count_for_version(version.id)
    assert_equal 1, GemDownload.count_for_rubygem(rubygem.id)
    assert_equal 0, GemDownload.count_for_version(other_platform_version.id)

    assert_equal 1, GemDownload.total_count
  end

  should "track version count" do
    version = create(:version)
    counts = Array.new(3) { |n| [version.full_name, n + 1] }
    GemDownload.bulk_update(counts)
    assert_equal 6, GemDownload.count_for_version(version.id)
  end

  should "find most downloaded all time" do
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)
    @version_2 = create(:version, rubygem: @rubygem_1)

    @rubygem_2 = create(:rubygem)
    @version_3 = create(:version, rubygem: @rubygem_2)

    @rubygem_3 = create(:rubygem)
    @version_4 = create(:version, rubygem: @rubygem_3)

    GemDownload.increment(1, rubygem_id: @rubygem_1, version_id: @version_1.id)
    GemDownload.increment(1, rubygem_id: @rubygem_1, version_id: @version_2.id)
    GemDownload.increment(1, rubygem_id: @rubygem_2, version_id: @version_3.id)
    GemDownload.increment(1, rubygem_id: @rubygem_3, version_id: @version_1.id)
    3.times { GemDownload.increment(1, rubygem_id: @rubygem_2, version_id: @version_3.id) }
    2.times { GemDownload.increment(1, rubygem_id: @rubygem_1, version_id: @version_2.id) }

    gem_download_order = [@version_3, @version_2, @version_1, @version_4].map(&:gem_download)
    assert_equal gem_download_order, GemDownload.most_downloaded_gems
  end

  should "find download count by gems id" do
    rubygem = create(:rubygem)
    version1 = create(:version, rubygem: rubygem)
    version2 = create(:version, rubygem: rubygem)
    GemDownload.bulk_update([[version1.full_name, 3], [version2.full_name, 2]])

    assert_equal 5, GemDownload.count_for_rubygem(rubygem.id)
    assert_equal 3, GemDownload.count_for_version(version1.id)
    assert_equal 2, GemDownload.count_for_version(version2.id)
  end

  should "not allow the same gemdownload twice" do
    create(:gem_download, rubygem_id: 1, version_id: 0)
    assert_raises(ActiveRecord::RecordNotUnique) do
      GemDownload.create!(rubygem_id: 1, version_id: 0)
    end
  end
end
