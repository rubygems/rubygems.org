# NOTE: This migration can be deployed manually in advance to prevent DB locks using following SQL statements.
#       Since it just adds new column to index, it works well with old ad new code at the same time.
#
#  CREATE INDEX CONCURRENTLY index_versions_on_position_and_rubygem_id ON versions USING btree(position, rubygem_id);
#  DROP INDEX CONCURRENTLY index_versions_on_position;
#  INSERT INTO schema_migrations VALUES (('20230121005809'));
class AddRubygemToPositionVersionsIndex < ActiveRecord::Migration[7.0]
  def up
    add_index :versions, %i[position rubygem_id]
    remove_index :versions, :position
  end

  def down
    add_index :versions, :position
    remove_index :versions, %i[position rubygem_id]
  end
end
