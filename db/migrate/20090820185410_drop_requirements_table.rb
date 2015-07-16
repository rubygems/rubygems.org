class DropRequirementsTable < ActiveRecord::Migration
  def self.up
    add_column :dependencies, :version_id, :integer
    rename_column :dependencies, :name, :requirements

    execute %{
      UPDATE
        dependencies
      SET
        version_id = (
          SELECT
            version_id
          FROM
            requirements
          WHERE
            requirements.dependency_id = dependencies.id
        )
    }.squish

    drop_table :requirements
  end

  def self.down
    create_table :requirements do |t|
      t.integer :version_id
      t.integer :dependency_id
    end

    execute %{
      INSERT INTO
        requirements (version_id, dependency_id)
      SELECT
        version_id, id
      FROM
        dependencies
    }.squish

    rename_column :dependencies, :requirements, :name
    remove_column :dependencies, :version_id
  end
end
