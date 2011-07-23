And /the following gem dependencies exist:/ do |table|
  table.hashes.each do |hash|
    version        = Version.find_by_full_name!(hash['Version'])
    rubygem        = Factory(:rubygem, :name => hash['Rubygem'])
    gem_dependency = Gem::Dependency.new(rubygem.name, hash['Requirements'])

    Factory(:dependency, :version => version, :rubygem => rubygem, :gem_dependency => gem_dependency)
  end
end

When /^I request dependencies with (\d+) gems$/ do |count|
  gems = count.to_i.times.map { |n| "zergling#{n}" }.join(",")
  visit "/api/v1/dependencies?gems=#{gems}"
end

Then /^I see status code (\d+)$/ do |code|
  assert_equal code.to_i, page.status_code
end
