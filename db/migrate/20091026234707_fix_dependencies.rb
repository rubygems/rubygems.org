class FixDependencies < ActiveRecord::Migration[4.2]
  def self.up
    # fix bad version reqs
    Dependency.all.each do |dep|
      reqs = dep.requirements
      begin
        Gem::Requirement.new(reqs)
      rescue ArgumentError
        list = reqs.split(/(>=)|(<=)|(~>)|(>)|(<)|(=)/).reject(&:empty?)
        fixed = list[0] + list[1] + ", " + list[2] + list[3]

        dep.update_attribute(:requirements, fixed)
      end
    end

    # kill bad deps too
    Dependency.includes(:rubygem).where(rubygems: { id: nil }).destroy_all
  end

  def self.down
    # yeah, no way
  end
end
