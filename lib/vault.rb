module Vault
  module S3
    BUCKET = Rails.env.maintenance? ? "production" : Rails.env

    def directory
      $fog.directories.new(:key => "#{BUCKET}.s3.rubygems.org")
    end

    def write_gem
      directory.files.create(
        :body => body.string,
        :key  => "gems/#{spec.original_name}.gem"
      )

      quick_path = "quick/Marshal.4.8/#{spec.original_name}.gemspec.rz"
      Pusher.indexer.abbreviate spec
      Pusher.indexer.sanitize spec

      directory.files.create(
        :body => Gem.deflate(Marshal.dump(spec)),
        :key  => "quick/Marshal.4.8/#{spec.original_name}.gemspec.rz"
      )
    end

    def upload(key, value)
      final = StringIO.new
      gzip = Zlib::GzipWriter.new(final)
      gzip.write(Marshal.dump(value))
      gzip.close

      # For the life of me, I can't figure out how to pass a stream in here from a closed StringIO
      directory.files.create(
        :body => final.string,
        :key  => key
      )
    end
  end

  module FS
    def write_gem
      cache_path = Pusher.server_path('gems', "#{spec.original_name}.gem")
      File.open(cache_path, "wb") do |f|
        f.write body.string
      end
      File.chmod 0644, cache_path

      quick_path = Pusher.server_path("quick", "Marshal.4.8", "#{spec.original_name}.gemspec.rz")
      FileUtils.mkdir_p(File.dirname(quick_path))

      Pusher.indexer.abbreviate spec
      Pusher.indexer.sanitize spec
      File.open(quick_path, "wb") do |f|
        f.write Gem.deflate(Marshal.dump(spec))
      end
      File.chmod 0644, quick_path
    end

    def upload(key, value)
      final = StringIO.new
      gzip = Zlib::GzipWriter.new(final)
      gzip.write(Marshal.dump(value))
      gzip.close

      File.open(Pusher.server_path(key), "wb") do |f|
        f.write final.string
      end
    end
  end
end
