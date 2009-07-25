module Vault
  module S3
    OPTIONS = {:authenticated => false, :access => :public_read}

    def store
      write
      update
    end

    def source_path
      "source_index"
    end

    def source_index
      if VaultObject.exists?(source_path)
        @source_index ||= Marshal.load(Gem.inflate(VaultObject.value(source_path)))
      else
        @source_index ||= Gem::SourceIndex.new
      end
    end

    def write
      cache_path = "gems/#{spec.original_name}.gem"
      VaultObject.store(cache_path, data.string, OPTIONS)

      quick_path = "quick/Marshal.#{Gem.marshal_version}/#{spec.original_name}.gemspec.rz"
      Gemcutter.indexer.abbreviate spec
      Gemcutter.indexer.sanitize spec
      VaultObject.store(quick_path, Gem.deflate(Marshal.dump(spec)), OPTIONS)
    end

    def update
      source_index.add_spec spec, spec.original_name
      VaultObject.store(source_path, Gem.deflate(Marshal.dump(source_index)), OPTIONS)

      specs_index = "specs.#{Gem.marshal_version}.gz"
      latest_specs_index = "latest_specs.#{Gem.marshal_version}.gz"

      [specs_index, latest_specs_index].each do |index|
        if VaultObject.exists?(index)
          binary = VaultObject.value(index)
          marshalled = Zlib::GzipReader.new(StringIO.new(binary)).read
          loaded_index = Marshal.load(marshalled)
        else
          loaded_index = []
        end

        source_index.each do |_, spec|
          platform = spec.original_platform
          platform = Gem::Platform::RUBY if platform.nil? or platform.empty?
          loaded_index << [spec.name, spec.version, platform]
        end

        loaded_index = Gemcutter.indexer.compact_specs(loaded_index).uniq

        final_index = StringIO.new
        gzip = Zlib::GzipWriter.new(final_index)
        gzip.write(Marshal.dump(loaded_index))
        gzip.close

        VaultObject.store(index, final_index.string, OPTIONS)
      end
    end

  end

  module FS
    def store
      write
      update
    end

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

    def write
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

    def update
      source_index.add_spec spec, spec.original_name
      File.open(source_path, "wb") do |f|
        f.write Marshal.dump(source_index)
      end

      Gemcutter.indexer.update_index(source_index)
    end
  end
end
