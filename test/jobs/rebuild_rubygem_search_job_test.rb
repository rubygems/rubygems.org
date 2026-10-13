# frozen_string_literal: true

require "test_helper"

class RebuildRubygemSearchJobTest < ActiveJob::TestCase
  setup do
    @original_suffix = Searchkick.index_suffix
    Searchkick.index_suffix = "rebuild_#{SecureRandom.hex(6)}"
    Rubygem.reindex(import: false)
    @index = Rubygem.searchkick_index
    @old_index = Searchkick.client.indices.get_alias(name: @index.name).keys.sole
  end

  teardown do
    @index.delete
    @index.clean_indices
    Searchkick.index_suffix = @original_suffix
  end

  test "rebuilding mappings and all documents without publication side effects" do
    published = create(:version, rubygem: create(:rubygem, name: "rebuild-published"))
    yanked = create(:version, :yanked, rubygem: create(:rubygem, name: "rebuild-yanked"))
    unversioned = create(:rubygem, name: "rebuild-unversioned")
    Searchkick.client.indices.put_mapping(index: @old_index, body: { properties: { legacy_only: { type: "keyword" } } })
    Searchkick.client.index(index: @index.name, id: "orphan", body: { name: "orphan" }, refresh: true)

    assert_no_enqueued_jobs do
      assert_no_difference -> { ActionMailer::Base.deliveries.count } do
        RebuildRubygemSearchJob.perform_now
      end
    end

    new_index = Searchkick.client.indices.get_alias(name: @index.name).keys.sole

    refute_equal @old_index, new_index
    mappings = Searchkick.client.indices.get_mapping(index: new_index).dig(new_index, "mappings", "properties")

    assert_equal "long", mappings.dig("downloads", "type")
    assert_equal "rubygem", mappings.dig("name", "analyzer")
    refute mappings.key?("legacy_only")
    assert_equal Rubygem.count, Searchkick.client.count(index: @index.name)["count"]
    refute Searchkick.client.exists?(index: @index.name, id: "orphan")
    published_data = Searchkick.client.get(index: @index.name, id: published.rubygem_id).fetch("_source")

    assert_equal "rebuild-published", published_data["name"]
    assert_equal published.number, published_data["version"]
    refute published_data["yanked"]
    [yanked.rubygem_id, unversioned.id].each do |id|
      assert Searchkick.client.get(index: @index.name, id:).dig("_source", "yanked")
    end
  end

  test "surfacing import failure without automatically retrying or promoting" do
    create(:version)
    stub_request(:post, %r{/_bulk}).to_return(
      body: { errors: true, items: [index: { error: { type: "mapper_parsing_exception", reason: "invalid document" } }] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    assert_no_enqueued_jobs do
      assert_raises(Searchkick::ImportError) { RebuildRubygemSearchJob.perform_now }
    end

    assert_equal [@old_index], Searchkick.client.indices.get_alias(name: @index.name).keys
  end
end
