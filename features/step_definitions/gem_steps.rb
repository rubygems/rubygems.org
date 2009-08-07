def build_gem(name, version, summary = "Gemcutter")
  FileUtils.rm_rf(name) if File.exists?(name)
  `jeweler #{name} --summary "#{summary}";`
  `cd #{name}; echo "#{version}" > VERSION; rake gemspec build 2>&1 /dev/null;`
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  build_gem(name, version)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and summary "([^\"]*)"$/ do |name, version, summary|
  build_gem(name, version, summary)
end

Given /^a rubygem exists with name "([^\"]*)" and rubyforge project "([^\"]*)"$/ do |name, rubyforge_project|
  rubygem = Factory(:rubygem, :name => name)
  Factory(:version, :rubygem => rubygem, :rubyforge_project => rubyforge_project)
end

