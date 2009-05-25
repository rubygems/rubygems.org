class Gemcutter
  def self.server_path(*more)
    File.join(File.dirname(__FILE__), '..', 'server', *more)
  end
end
