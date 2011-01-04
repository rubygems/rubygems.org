namespace :asset_cache do
	desc 'Clear the cached asset files (Run in production)'
	task :clear do
		asset_cache_path = File.join(File.dirname(__FILE__), "..", "..", "..", "..", "tmp", "asset_cache")
		if File.directory?(asset_cache_path)
			Dir.entries(asset_cache_path).each do |file|
				next if file == "." || file == ".."
				File.delete(File.join(asset_cache_path, file))
			end
		end
	end
end
