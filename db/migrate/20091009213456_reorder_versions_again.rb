class ReorderVersionsAgain < ActiveRecord::Migration
  def self.up
    Rubygem.all.each(&:reorder_versions)
  end

  def self.down
  end
end
