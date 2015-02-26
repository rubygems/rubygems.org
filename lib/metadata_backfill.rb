require 'stringio'

class MetadataBackfill
  attr_reader :version

  def initialize(version)
    @version = version
  end

  def backfill
    file = dir.files.get(key) or return
    pusher = Pusher.new(nil, StringIO.new(file.body))
    pusher.pull_spec
    version.update_attributes(metadata: pusher.spec.metadata || {})
  end

  private

  def dir
    Indexer.new.directory
  end

  def key
    "gems/#{version.full_name}.gem"
  end
end
