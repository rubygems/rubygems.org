require 'test_helper'

class GemDownloadTest < ActiveSupport::TestCase
  setup do
    GemDownload.create!(count: 0, rubygem_id: 0, version_id: 0)
  end

  context "#increment" do
    should "load up all downloads with just raw strings and process them" do
      rubygem = create(:rubygem, name: "gem123")
      version = create(:version, rubygem: rubygem)

      3.times do
        GemDownload.increment(rubygem.name, version.full_name)
      end

      assert_equal 3, GemDownload.count_for_version(version.id)
      assert_equal 3, GemDownload.count_for_rubygem(rubygem.id)
      assert_equal 3, GemDownload.total_count
    end

    should "take optional count kwarg" do
      version = create(:version)
      rubygem = version.rubygem

      GemDownload.increment(rubygem.name, version.full_name, count: 100)

      assert_equal 100, GemDownload.count_for_version(version.id)
      assert_equal 100, GemDownload.count_for_rubygem(rubygem.id)
    end
  end

  context "#bulk_update" do
    should "write the proper values" do
      versions = Array.new(2) { create(:version) }
      gems     = versions.map(&:rubygem)
      counts   = Array.new(2) { rand(100) }
      data     = gems.map(&:name).zip(versions.map(&:full_name), counts)

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

    GemDownload.increment(rubygem.name, version.full_name)

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

    GemDownload.increment(@rubygem_1.name, @version_1.full_name)
    GemDownload.increment(@rubygem_1.name, @version_2.full_name)
    GemDownload.increment(@rubygem_2.name, @version_3.full_name)
    GemDownload.increment(@rubygem_1.name, @version_1.full_name)
    3.times { GemDownload.increment(@rubygem_2.name, @version_3.full_name) }
    2.times { GemDownload.increment(@rubygem_1.name, @version_2.full_name) }

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

    3.times { GemDownload.increment(rubygem.name, version1.full_name) }
    2.times { GemDownload.increment(rubygem.name, version2.full_name) }

    assert_equal 5, GemDownload.count_for_rubygem(rubygem.id)
    assert_equal 3, GemDownload.count_for_version(version1.id)
    assert_equal 2, GemDownload.count_for_version(version2.id)
  end

  should "return zero for rank if no downloads exist" do
    skip "fixme"
    assert_equal 0, Download.rank(build(:version))
  end
end
