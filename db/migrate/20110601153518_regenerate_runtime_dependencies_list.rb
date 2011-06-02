class RegenerateRuntimeDependenciesList < ActiveRecord::Migration
  def self.up
    count = 0
    batch_size = 10000
    Dependency.find_each(:batch_size => batch_size, :include => :version) do |dep|
      puts count if count % batch_size == 0
      if dep.version
        $redis.del(Dependency.runtime_key(dep.version.full_name))
        dep.send(:push_on_to_list)
      end
      count += 1
    end
  end

  def self.down
  end
end
