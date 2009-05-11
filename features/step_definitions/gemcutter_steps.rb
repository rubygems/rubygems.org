Before do
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
end

After do
  Dir.chdir(TEST_DIR)
  FileUtils.rm_rf(TEST_DIR)
end

Given /^I have a gem "([^\"]*)"$/ do |name|
  system("jeweler #{name} --summary test >> /dev/null")
  Dir.chdir(name)
end

When /^I build the gem$/ do
  system("rake version:write gemspec build >> /dev/null 2> /dev/null")
end

When /^I push "([^\"]*)"$/ do |gem|
  Gem::GemRunner.new.run(["push", gem])
end
