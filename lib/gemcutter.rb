class Gemcutter
  def self.server_path(*more)
    File.join(File.dirname(__FILE__), '..', 'server', *more)
  end

  def self.indexer
    indexer = Gem::Indexer.new(Gemcutter.server_path, :build_legacy => false)
    def indexer.say(message) end
    indexer
  end
end
