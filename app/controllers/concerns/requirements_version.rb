require "rubygems/dependency"

module RequirementsVersion
  extend ActiveSupport::Concern

  included do
    def dep_resolver(name, reqs, versions)
      reqs = Gem::Dependency.new(name, reqs.split(/\s*,\s*/))

      versions.each do |ver|
        return ver if reqs.match?(name, ver)
      end
    end
  end
end
