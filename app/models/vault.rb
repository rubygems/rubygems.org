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
    # For the life of me, I can't figure out how to pass a stream in here from a closed StringIO
    file = directory.files.create(
      :body   => stringify(value),
      :key    => key,
      :public => true
    )
  end

  def generate_graph
    dep_graph = DependencyGraph.new(spec)
    %w{png svg svgz}.each do |format|
      graph_path = Pusher.server_path('graphs', "#{spec.original_name}.#{format}")
      file = directory.files.new(
        :body => dep_graph.graph.output(format.to_sym => String),
        :key => "graphs/#{spec.original_name}.#{format}"
      )
      file.save('x-amz-acl' => 'public-read')
    end
  end
end
