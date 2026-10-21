# frozen_string_literal: true

require "test_helper"

class Maintenance::ReindexGemsWithNewerPlatformReleasesTaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return gems whose newest release is for a platform other than ruby" do
      newer_platform = create(:rubygem)
      create(:version, rubygem: newer_platform, number: "1.0.0")
      create(:version, rubygem: newer_platform, number: "2.0.0", platform: "java")

      newer_ruby = create(:rubygem)
      create(:version, rubygem: newer_ruby, number: "2.0.0")
      create(:version, rubygem: newer_ruby, number: "1.0.0", platform: "java")

      platform_only = create(:rubygem)
      create(:version, rubygem: platform_only, number: "1.0.0", platform: "java")

      same_number = create(:rubygem)
      create(:version, rubygem: same_number, number: "1.0.0")
      create(:version, rubygem: same_number, number: "1.0.0", platform: "java")

      assert_equal [newer_platform], Maintenance::ReindexGemsWithNewerPlatformReleasesTask.collection.to_a
    end
  end

  context "#process" do
    should "reindex the gem with its newest release" do
      rubygem = create(:rubygem)
      create(:version, rubygem: rubygem, number: "1.0.0")
      rubygem.reindex(refresh: true)
      create(:version, rubygem: rubygem, number: "2.0.0", platform: "java")

      Maintenance::ReindexGemsWithNewerPlatformReleasesTask.process(rubygem)
      Rubygem.searchkick_index.refresh

      document = Searchkick.client.get(index: Rubygem.searchkick_index.name, id: rubygem.id)["_source"]

      assert_equal %w[2.0.0 java], document.values_at("version", "platform")
    end
  end
end
