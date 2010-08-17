And "the following dependencies exist:" do |table|
  table.hashes.each do |hash|
    version        = Version.find_by_full_name!(hash['Version'])
    rubygem        = Factory(:rubygem, :name => hash['Rubygem'])
    gem_dependency = Gem::Dependency.new(rubygem.name, hash['Requirements'])

    Factory(:dependency, :version => version, :rubygem => rubygem, :gem_dependency => gem_dependency)
  end
end
