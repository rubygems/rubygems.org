Given 'a Rails app' do
  system "rails rails_root"
  @rails_root = File.join(File.dirname(__FILE__), "..", "..", "rails_root")
end

Given /^the coulda plugin is installed$/ do
  plugin_dir = File.join(@rails_root, "vendor", "plugins")
  target     = File.join(File.dirname(__FILE__), "..", "..", "generators")
  FileUtils.mkdir_p "#{plugin_dir}/coulda"
  system "cp -r #{target} #{plugin_dir}/coulda"
end

After do
  FileUtils.rm_rf @rails_root if @rails_root
end

