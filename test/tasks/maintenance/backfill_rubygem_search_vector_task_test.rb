# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillRubygemSearchVectorTaskTest < ActiveSupport::TestCase
  context "#collection" do
    should "return only rubygems with indexed versions" do
      with_versions = create(:rubygem, name: "with_versions")
      create(:version, rubygem: with_versions)
      create(:rubygem, name: "without_versions", indexed: false)

      assert_equal [with_versions], Maintenance::BackfillRubygemSearchVectorTask.collection.to_a
    end
  end

  context "#process" do
    should "populate the search_vector from name, summary and description" do
      rubygem = create(:rubygem, name: "widget")
      create(:version, rubygem: rubygem, summary: "a useful gadget", description: "does widget things")

      assert_nil rubygem.reload.search_vector

      Maintenance::BackfillRubygemSearchVectorTask.process(rubygem)

      assert_predicate rubygem.reload.search_vector, :present?
      assert_includes Rubygem.where("search_vector @@ websearch_to_tsquery('english', 'gadget')"), rubygem
    end
  end
end
