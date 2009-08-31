module Vault
  module S3
    OPTIONS = {:authenticated => false, :access => :public_read}

    def store
      write_gem
      update_index
    end

    def source_path
      "index"
    end

    def source_index
      @source_index ||= Rails.cache.fetch(source_path) do
        if VaultObject.exists?(source_path)
          binary = VaultObject.value(source_path)
          marshalled = Zlib::GzipReader.new(StringIO.new(binary)).read
          source_index = Marshal.load(marshalled)
          Rails.cache.write(source_path, source_index)
          source_index
        else
          raise "Missing source index, we're in trouble."
        end
      end
    end

    def write_gem
      cache_path = "gems/#{spec.original_name}.gem"
      VaultObject.store(cache_path, data.string, OPTIONS)

      quick_path = "quick/Marshal.#{Gem.marshal_version}/#{spec.original_name}.gemspec.rz"
      Gemcutter.indexer.abbreviate spec
      Gemcutter.indexer.sanitize spec
      VaultObject.store(quick_path, Gem.deflate(Marshal.dump(spec)), OPTIONS)
    end

    def update_index
      source_index.add_spec(spec)

      # TODO: throw this in a rake task and cron it
      # upload(source_path, source_index)
      indexify("specs.#{Gem.marshal_version}.gz", source_index.gems)
      indexify("latest_specs.#{Gem.marshal_version}.gz", source_index.latest_specs)
    end

    def indexify(key, specs)
      upload(key, specs.map { |*raw_spec|
        spec = raw_spec.flatten.last
        platform = spec.original_platform
        platform = Gem::Platform::RUBY if platform.nil? or platform.empty?
        [spec.name, spec.version, platform]
      })
    end

    def upload(key, data)
      final = StringIO.new
      gzip = Zlib::GzipWriter.new(final)
      gzip.write(Marshal.dump(data))
      gzip.close

      # For the life of me, I can't figure out how to pass a stream in here from a closed StringIO
      VaultObject.store(key, final.string, OPTIONS)
    end

  end

  module FS
    def store
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
        f.write data.string
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
