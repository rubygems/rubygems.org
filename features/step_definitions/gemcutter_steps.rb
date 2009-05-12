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
  gem = Rack::Test::UploadedFile.new(gem).open
  post "/gems", {}, {"rack.input" => gem}
end
