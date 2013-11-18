class Indexer
  def perform
    log "Updating the index"
    update_index
    log "Finished updating the index"
  end

  def write_gem(body, spec)
    gem_file = Tuf::File.from_body(
      "gems/#{spec.original_name}.gem",
      body.string
    )

    self.class.indexer.abbreviate spec
    self.class.indexer.sanitize spec

    gem_spec = Tuf::File.from_body(
      "quick/Marshal.4.8/#{spec.original_name}.gemspec.rz",
      Gem.deflate(Marshal.dump(spec))
    )

    files = [
      gem_file,
      gem_spec,
    ]

    files.each do |file|
      # These files are stored without their hash in the filename since they
      # are immutable, so there is no risk of two different versions appearing
      # in two different snapshots. TUF will still verify the hashes that are
      # stored in metadata, and legacy clients will be able to find files where
      # they expect them.
      file_bucket.create(file.path, file.body)
    end

    tuf_pending_store.add(files)
  end

  def directory
    fog.directories.get($rubygems_config[:s3_bucket]) || fog.directories.create(:key => $rubygems_config[:s3_bucket])
  end

  private

  def fog
    $fog || Fog::Storage.new(
      :provider => 'Local',
      :local_root => Pusher.server_path
    )
  end

  def stringify(value)
    final = StringIO.new
    gzip = Zlib::GzipWriter.new(final)
    gzip.write(Marshal.dump(value))
    gzip.close

    final.string
  end

  def upload(path, value)
    content = stringify(value)
    file    = Tuf::File.from_body(path, content)

    # The index files are stored with their hash in the path to support the
    # consistent snapshots provided by TUF.
    #
    # A version without the hash is also stored to support legacy clients.
    file_bucket.create(file.path_with_hash, file.body)
    file_bucket.create(file.path, file.body)

    file
  end

  def tuf_pending_store
    @tuf_pending_store ||= Tuf::RedisPendingStore.new($redis)
  end

  def file_bucket
    @file_bucket ||= PublicFileBucket.new(directory)
  end

  def tuf_repo
    @tuf_repo ||= Tuf::OnlineRepository.new(
      root:   JSON.parse(read_with_error('config/root.txt', "No root.txt available.")),
      bucket: file_bucket,
      online_key: Tuf::Key.build('rsa',
        File.read('config/keys/online-private.pem'),
        File.read('config/keys/online-public.pem')
      )
    )
  end

  def read_with_error(path, msg)
    File.read(path)
  rescue
    raise msg
  end

  # TODO: Integration test for this
  def update_index
    index_files = []
    index_files << upload("specs.4.8.gz", specs_index)
    log "Uploaded all specs index"
    index_files << upload("latest_specs.4.8.gz", latest_index)
    log "Uploaded latest specs index"
    index_files << upload("prerelease_specs.4.8.gz", prerelease_index)
    log "Uploaded prerelease specs index"

    index_files.each do |file|
      tuf_repo.replace_file(file, 'targets/unclaimed', 'targets')
    end

    # For now assume all files are unclaimed
    pending_files = tuf_pending_store.pending
    pending_files.each do |file|
      puts "Adding file: #{file.path}"
      tuf_repo.add_file(file, 'targets/unclaimed', 'targets')
    end
    tuf_repo.publish!
    tuf_pending_store.clear(pending_files)
  end

  def minimize_specs(data)
    names     = Hash.new { |h,k| h[k] = k }
    versions  = Hash.new { |h,k| h[k] = Gem::Version.new(k) }
    platforms = Hash.new { |h,k| h[k] = k }

    data.each do |row|
      row[0] = names[row[0]]
      row[1] = versions[row[1].strip]
      row[2] = platforms[row[2]]
    end

    data
  end

  def specs_index
    minimize_specs Version.rows_for_index
  end

  def latest_index
    minimize_specs Version.rows_for_latest_index
  end

  def prerelease_index
    minimize_specs Version.rows_for_prerelease_index
  end

  def log(message)
    Rails.logger.info "[GEMCUTTER:#{Time.now}] #{message}"
  end

  def self.indexer
    @indexer ||=
      begin
        indexer = Gem::Indexer.new(Pusher.server_path, :build_legacy => false)
        def indexer.say(message) end
        indexer
      end
  end
end
