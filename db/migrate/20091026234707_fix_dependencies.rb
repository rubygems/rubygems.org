class FixDependencies < ActiveRecord::Migration
  def self.up
    # fix bad version reqs
    Dependency.all.each do |dep|
      reqs = dep.requirements
      begin
        Gem::Requirement.new(reqs)
      rescue ArgumentError => ex
        list = reqs.split(/(>=)|(<=)|(~>)|(>)|(<)|(=)/).reject(&:empty?)
        fixed = list[0] + list[1] + ", " + list[2] + list[3]

        dep.update_attribute(:requirements, fixed)
      end
    end

    # kill bad deps too
    Dependency.includes(:rubygem).select { |v| v.rubygem.nil? }.each { |d| d.destroy }
  end

  def self.down
    # yeah, no way
  end
end
