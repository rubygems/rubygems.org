# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillDeletionVersionsTaskTest < ActiveSupport::TestCase
  test "#collection" do
    assert_equal Deletion.all, Maintenance::BackfillDeletionVersionsTask.collection
  end

  test "#process" do
    version = create(:version)
    deletion = create(:deletion, version:)

    deletion.update_column(:version_id, nil)

    assert_nil deletion.version_id

    Maintenance::BackfillDeletionVersionsTask.process(deletion)

    assert_equal version.id, deletion.version_id
    assert_equal version, deletion.version

    assert_no_changes -> { deletion.reload.as_json } do
      Maintenance::BackfillDeletionVersionsTask.process(deletion)
    end
  end

  test "#process with deleted user" do
    version = create(:version)
    deletion = create(:deletion, version:)

    deletion.update_column(:version_id, nil)

    assert_nil deletion.version_id

    deletion.user.destroy!

    Maintenance::BackfillDeletionVersionsTask.process(deletion.reload)

    assert_equal version.id, deletion.version_id
    assert_equal version, deletion.version
  end

  test "#process with changed gem capitalization" do
    rubygem = create(:rubygem, name: "rubygem0")
    version = create(:version, rubygem:)
    deletion = create(:deletion, version:)

    deletion.update_column(:version_id, nil)

    assert_nil deletion.version_id

    rubygem.update!(name: "Rubygem0")

    Maintenance::BackfillDeletionVersionsTask.process(deletion.reload)

    assert_equal version.id, deletion.version_id
    assert_equal version, deletion.version
  end

  test "#process with missing version" do
    Deletion.insert!({ rubygem: "missing", number: "1.0.0", platform: "ruby" })
    deletion = Deletion.where(rubygem: "missing", number: "1.0.0", platform: "ruby").sole

    assert_nil deletion.version_id

    Maintenance::BackfillDeletionVersionsTask.process(deletion)

    assert_nil deletion.version_id
  end
end
