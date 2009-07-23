module Vault
  module S3
    def store
      puts "this works?"
    end
  end

  module FS
    def source_path
      Gemcutter.server_path("source_index")
    end

    def source_index
      if File.exists?(source_path)
        @source_index ||= Marshal.load(File.open(source_path))
      else
        @source_index ||= Gem::SourceIndex.new
      end
    end

    def store
      write
      update
    end

    def write
      cache_path = Gemcutter.server_path('gems', "#{spec.original_name}.gem")
      File.open(cache_path, "wb") do |f|
        f.write data
      end
      File.chmod 0644, cache_path

      quick_path = Gemcutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{spec.original_name}.gemspec.rz")
      FileUtils.mkdir_p(File.dirname(quick_path))

      Gemcutter.indexer.abbreviate spec
      Gemcutter.indexer.sanitize spec
      File.open(quick_path, "wb") do |f|
        f.write Gem.deflate(Marshal.dump(spec))
      end
      File.chmod 0644, quick_path
    end

    def update
      source_index.add_spec spec, spec.original_name
      File.open(source_path, "wb") do |f|
        f.write Marshal.dump(source_index)
      end

      Gemcutter.indexer.update_index(source_index)
    end
  end
end
