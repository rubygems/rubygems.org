class ReorderVersionsAgain < ActiveRecord::Migration[4.2]
  def self.up
    Rubygem.all.each(&:reorder_versions)
  end

  def self.down
  end
end
