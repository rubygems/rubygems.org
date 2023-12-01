# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillVersionRubygemNameTaskTest < ActiveSupport::TestCase
  test "#collection" do
    assert_equal Version.all.includes(:rubygem), Maintenance::BackfillVersionRubygemNameTask.collection
  end

  test "#process" do
    rubygem = create(:rubygem, name: "rubygem0")
    version = create(:version, rubygem:)

    version.update_column(:rubygem_name, nil)

    assert_nil version.rubygem_name

    Maintenance::BackfillVersionRubygemNameTask.process(version)

    assert_equal "rubygem0", version.rubygem_name
  end
end
