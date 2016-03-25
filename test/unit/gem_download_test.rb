require 'test_helper'

class GemDownloadTest < ActiveSupport::TestCase
  setup do
    create(:gem_download, count: 0)
  end

  context "update_count_by" do
    should "not update if download doesnt exist" do
      assert_nil GemDownload.update_count_by(1, rubygem_id: 1)
    end

    should "not update if download count is nil" do
      GemDownload.create!(rubygem_id: 1, version_id: 0)
      download = GemDownload.update_count_by(1, rubygem_id: 1)
      assert_nil download.count
    end

    should "update the count" do
      GemDownload.create!(rubygem_id: 1, version_id: 1, count: 0)
      GemDownload.update_count_by(1, rubygem_id: 1, version_id: 1)

      assert_equal 1, GemDownload.where(rubygem_id: 1, version_id: 1).first.count
    end
  end

  uses_transaction :test_update_the_count_atomically
  def test_update_the_count_atomically
    create(:gem_download, rubygem_id: 1, version_id: 1, count: 0)

    25.times do
      Array.new(4) do
        Thread.new { GemDownload.update_count_by(1, rubygem_id: 1, version_id: 1) }
      end.each(&:join)
    end

    assert_equal 100, GemDownload.where(rubygem_id: 1, version_id: 1).first.count
  ensure
    GemDownload.delete_all
  end

  context "#increment" do
    should "dont increment if entry doesnt exists" do
      assert_nil GemDownload.increment("rails-3.2.22")
    end

    should "load up all downloads with just raw strings and process them" do
      rubygem = create(:rubygem, name: "gem123")
      version = create(:version, rubygem: rubygem)

      3.times do
        GemDownload.increment(version.full_name)
      end

      assert_equal 3, GemDownload.count_for_version(version.id)
      assert_equal 3, GemDownload.count_for_rubygem(rubygem.id)
      assert_equal 3, GemDownload.total_count
    end

    should "take optional count kwarg" do
      version = create(:version)
      rubygem = version.rubygem

      GemDownload.increment(version.full_name, count: 100)

      assert_equal 100, GemDownload.count_for_version(version.id)
      assert_equal 100, GemDownload.count_for_rubygem(rubygem.id)
    end
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

  should "track platform gem downloads correctly" do
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem, platform: "mswin32-60")
    other_platform_version = create(:version, rubygem: rubygem, platform: "mswin32")

    GemDownload.increment(version.full_name)

    assert_equal 1, GemDownload.count_for_version(version.id)
    assert_equal 1, GemDownload.count_for_rubygem(rubygem.id)
    assert_equal 0, GemDownload.count_for_version(other_platform_version.id)

    assert_equal 1, GemDownload.total_count
  end

  should "find most downloaded all time" do
    skip "fixme"
    @rubygem_1 = create(:rubygem)
    @version_1 = create(:version, rubygem: @rubygem_1)
    @version_2 = create(:version, rubygem: @rubygem_1)

    @rubygem_2 = create(:rubygem)
    @version_3 = create(:version, rubygem: @rubygem_2)

    @rubygem_3 = create(:rubygem)
    @version_4 = create(:version, rubygem: @rubygem_3)

    GemDownload.increment(@version_1.full_name)
    GemDownload.increment(@version_2.full_name)
    GemDownload.increment(@version_3.full_name)
    GemDownload.increment(@version_1.full_name)
    3.times { GemDownload.increment(@version_3.full_name) }
    2.times { GemDownload.increment(@version_2.full_name) }

    assert_equal [[@version_3, 4], [@version_2, 3], [@version_1, 2]],
      Download.most_downloaded_all_time

    assert_equal [[@version_3, 4], [@version_2, 3]],
      Download.most_downloaded_all_time(2)

    assert_equal 3, Download.cardinality
    assert_equal 1, Download.rank(@version_3)
    assert_equal 2, Download.rank(@version_2)
    assert_equal 3, Download.rank(@version_1)
  end

  should "find download count by gems id" do
    rubygem = create(:rubygem)
    version1 = create(:version, rubygem: rubygem)
    version2 = create(:version, rubygem: rubygem)

    3.times { GemDownload.increment(version1.full_name) }
    2.times { GemDownload.increment(version2.full_name) }

    assert_equal 5, GemDownload.count_for_rubygem(rubygem.id)
    assert_equal 3, GemDownload.count_for_version(version1.id)
    assert_equal 2, GemDownload.count_for_version(version2.id)
  end

  should "return zero for rank if no downloads exist" do
    skip "fixme"
    assert_equal 0, Download.rank(build(:version))
  end

  should "not allow the same gemdownload twice" do
    GemDownload.create!(rubygem_id: 1, version_id: 0)
    assert_raises(ActiveRecord::RecordNotUnique) do
      GemDownload.create!(rubygem_id: 1, version_id: 0)
    end
  end
end
