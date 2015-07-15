class ReallyRegenerateRuntimeDependenciesList < ActiveRecord::Migration
  def self.up
    each_dependency do |row|
      Redis.current.lrem "rd:#{row['full_name']}", 0, "#{row['name']} #{row['requirements']}"
    end
  end

  def self.down
    each_dependency do |row|
      Redis.current.lpush "rd:#{row['full_name']}", "#{row['name']} #{row['requirements']}"
    end
  end

  def self.each_dependency
    dependencies = <<-SQL
      select dependencies.*, name, full_name
      from dependencies
      inner join versions on versions.id = dependencies.version_id
      inner join rubygems on rubygems.id = dependencies.rubygem_id
      where scope = 'development'
    SQL
    connection.select_all(dependencies).each_with_index do |row, index|
      yield row
    end
  end
end
