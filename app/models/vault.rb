module Vault
  BUCKET = Rails.env.maintenance? ? "production" : Rails.env

  def self.cf_url_for(path)
    "http://#{BUCKET}.cf.rubygems.org#{path}"
  end

  def self.s3_url_for(path)
    "http://#{BUCKET}.s3.rubygems.org#{path}"
  end

  def fog
    $fog || Fog::Storage.new(
      :provider => 'Local',
      :local_root => Pusher.server_path('gems')
    )
  end

  def directory
    fog.directories.create(
      :key => "#{BUCKET}.s3.rubygems.org",
      :public => true
    )
  end

  def write_gem
    gem_file = directory.files.create(
      :body => body.string,
      :key  => "gems/#{spec.original_name}.gem"
    )

    Pusher.indexer.abbreviate spec
    Pusher.indexer.sanitize spec

    gem_spec = directory.files.create(
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
    file = directory.files.create(
      :acl  => 'public-read',
      :body => final.string,
      :key  => key
    )
  end
end
