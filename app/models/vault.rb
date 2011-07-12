module Vault
  def self.cf_url_for(path)
    "http://#{$rubygems_config[:cf_domain]}#{path}"
  end

  def self.s3_url_for(path)
    "http://#{$rubygems_config[:s3_domain]}#{path}"
  end

  def fog
    $fog || Fog::Storage.new(
      :provider => 'Local',
      :local_root => Pusher.server_path('gems')
    )
  end

  def directory
    fog.directories.get($rubygems_config[:s3_bucket])
  end

  def write_gem
    gem_file = directory.files.create(
      :body   => body.string,
      :key    => "gems/#{spec.original_name}.gem",
      :public => true
    )

    Pusher.indexer.abbreviate spec
    Pusher.indexer.sanitize spec

    gem_spec = directory.files.create(
      :body   => Gem.deflate(Marshal.dump(spec)),
      :key    => "quick/Marshal.4.8/#{spec.original_name}.gemspec.rz",
      :public => true
    )
  end

  def stringify(value)
    final = StringIO.new
    gzip = Zlib::GzipWriter.new(final)
    gzip.write(Marshal.dump(value))
    gzip.close

    final.string
  end

  def upload(key, value)
    file = directory.files.create(
      :body   => stringify(value),
      :key    => key,
      :public => true
    )
  end
end
