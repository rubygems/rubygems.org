module Vault
  module S3
    OPTIONS = {:authenticated => false, :access => :public_read}

    def perform
      write_gem
      update_index
    end

    def specs_index
      Version.with_indexed.map(&:to_index)
    end

    def latest_index
      Version.with_indexed.inject({}) { |memo, version|
        key = "#{version.rubygem_id}-#{version.platform}"
        memo[key] = version if memo[key].blank? || (version <=> memo[key]) == 1
        memo
      }.values.map(&:to_index)
    end

    def write_gem
      cache_path = "gems/#{spec.original_name}.gem"
      VaultObject.store(cache_path, self.raw_data, OPTIONS)

      quick_path = "quick/Marshal.#{Gem.marshal_version}/#{spec.original_name}.gemspec.rz"
      Gemcutter.indexer.abbreviate spec
      Gemcutter.indexer.sanitize spec
      VaultObject.store(quick_path, Gem.deflate(Marshal.dump(spec)), OPTIONS)
    end

    def update_index
      upload("specs.#{Gem.marshal_version}.gz", specs_index)
      upload("latest_specs.#{Gem.marshal_version}.gz", latest_index)
    end

    def upload(key, value)
      final = StringIO.new
      gzip = Zlib::GzipWriter.new(final)
      gzip.write(Marshal.dump(value))
      gzip.close

      # For the life of me, I can't figure out how to pass a stream in here from a closed StringIO
      VaultObject.store(key, final.string, OPTIONS)
    end
  end

  module FS
    def perform
      write_gem
      update_index
    end

    def source_path
      Gemcutter.server_path("source_index")
    end

    def source_index
      if File.exists?(source_path)
        @source_index ||= Marshal.load(Gem.inflate(File.read(source_path)))
      else
        @source_index ||= Gem::SourceIndex.new
      end
    end

    def write_gem
      cache_path = Gemcutter.server_path('gems', "#{spec.original_name}.gem")
      File.open(cache_path, "wb") do |f|
        f.write self.raw_data
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

    def update_index
      source_index.add_spec spec, spec.original_name
      File.open(source_path, "wb") do |f|
        f.write Gem.deflate(Marshal.dump(source_index))
      end

      Gemcutter.indexer.update_index(source_index)
    end
  end
end
