require 'test_helper'

class GemInfoTest < ActiveSupport::TestCase
  teardown do
    Rails.cache.clear
  end

  context '#compact_index_info' do
    setup do
      rubygem = create(:rubygem, name: 'example')
      version = create(:version, rubygem: rubygem, number: '1.0.0', info_checksum: 'qw2dwe')
      dep = create(:rubygem, name: 'exmaple_dep')
      create(:dependency, rubygem: dep, version: version)

      @expected_info = [CompactIndex::GemVersion.new(
        '1.0.0',
        'ruby',
        'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
        'qw2dwe',
        [CompactIndex::Dependency.new('exmaple_dep', '= 1.0.0')],
        '>= 2.0.0',
        '>= 2.6.3'
      )]
    end

    should 'return gem version and dependency' do
      info = GemInfo.new('example').compact_index_info
      assert_equal @expected_info, info
    end

    should 'write cache' do
      Rails.cache.stubs(:write)
      info = GemInfo.new('example').compact_index_info
      assert_received(Rails.cache, :write) { |cache| cache.with("info/example", info) }
    end

    should 'read from cache when cache exists' do
      GemInfo.new('example').compact_index_info
      Rails.cache.stubs(:read)
      info = GemInfo.new('example').compact_index_info
      assert_received(Rails.cache, :read) { |cache| cache.with("info/example") }
      assert_equal @expected_info, info
    end
  end

  context '.ordered_names' do
    setup do
      %w(abc bcd abd).each { |name| create(:rubygem, name: name) }
    end

    should 'order rubygems by name' do
      names = GemInfo.ordered_names
      assert_equal %w(abc abd bcd), names
    end

    should 'write cache' do
      Rails.cache.stubs(:write)
      names = GemInfo.ordered_names
      assert_received(Rails.cache, :write) { |cache| cache.with("names", names) }
    end

    should 'read from cache when cache exists' do
      GemInfo.ordered_names
      Rails.cache.stubs(:read)
      names = GemInfo.ordered_names
      assert_received(Rails.cache, :read) { |cache| cache.with("names") }
      assert_equal %w(abc abd bcd), names
    end
  end

  context '.compact_index_versions' do
    setup do
      create(:version, number: '0.0.1', created_at: 10.days.ago)
      rubygem = create(:rubygem, name: 'foo')
      create(:version, rubygem: rubygem, number: '2.0.0', created_at: 2.days.ago, info_checksum: 'qw2dwe')
      create(:version, rubygem: rubygem, number: '1.0.1', created_at: 3.days.ago, info_checksum: '32ddwe')

      @expected_versions =
        [CompactIndex::Gem.new('foo', [CompactIndex::GemVersion.new('1.0.1', 'ruby', nil, '32ddwe')]),
         CompactIndex::Gem.new('foo', [CompactIndex::GemVersion.new('2.0.0', 'ruby', nil, 'qw2dwe')])]
    end

    should "return all versions created after given date and ordered by created_at" do
      versions = GemInfo.compact_index_versions(4.days.ago)
      assert_equal @expected_versions, versions
    end
  end
end
