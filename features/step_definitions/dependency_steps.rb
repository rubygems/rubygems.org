And "the following dependencies exist:" do |table|
  table.hashes.each do |hash|
    version = Version.find_by_full_name!(hash['Version'])
    rubygem = Factory(:rubygem, :name => hash['Rubygem'])
    Factory(:dependency, :version => version, :rubygem => rubygem, :requirements => hash['Requirements'])
  end
end
