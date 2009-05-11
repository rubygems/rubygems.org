Before do
  @cleanup = []
end

After do
  @cleanup.each { |c| FileUtils.rm_rf(c) }
end

Given /^I have a built gem "([^\"]*)"$/ do |name|
  @cleanup << name
  FileUtils.rm_rf(name)
  system("jeweler #{name} --summary test >> /dev/null")
  system("cd #{name}; rake version:write gemspec build >> /dev/null 2> /dev/null")
end

When /^I push "([^\"]*)"$/ do |gem|
  Gem::GemRunner.new.run(["help"])
  #Gem::GemRunner.new.run(["push", gem])
end
