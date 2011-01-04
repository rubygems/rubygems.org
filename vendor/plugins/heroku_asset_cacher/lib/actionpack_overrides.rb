module ActionView
  module Helpers
		module AssetTagHelper
      private
				def write_asset_file_contents(joined_asset_path, asset_paths)
					joined_asset_path = File.join($asset_cache_base_path, joined_asset_path.split(File::SEPARATOR).last)
          FileUtils.mkdir_p(File.dirname(joined_asset_path))
          File.atomic_write(joined_asset_path) { |cache| cache.write(join_asset_file_contents(asset_paths)) }

          # Set mtime to the latest of the combined files to allow for
          # consistent ETag without a shared filesystem.
          mt = asset_paths.map { |p| File.mtime(asset_file_path(p)) }.max
          File.utime(mt, mt, joined_asset_path)
        end
		end
	end
end