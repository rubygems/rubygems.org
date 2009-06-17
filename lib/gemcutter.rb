class Gemcutter
  attr_reader :user, :data, :spec, :error_message, :error_code, :rubygem

  def initialize(user, data)
    @user = user
    @data = data
  end

  def process
    pull_spec
    find_rubygem if self.spec
  end

  def pull_spec
    begin
      format = Gem::Format.from_io(data)
      @spec = format.spec
    rescue Exception => e
      @error_message = "Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid."
      @error_code = 422
    end
  end

  def find_rubygem
    @rubygem = Rubygem.find_or_initialize_by_name(@spec.name)
  end

  class << self
    def server_path(*more)
      File.expand_path(File.join(File.dirname(__FILE__), '..', 'server', *more))
    end

    def indexer
      indexer = Gem::Indexer.new(Gemcutter.server_path, :build_legacy => false)
      def indexer.say(message) end
      indexer
    end
  end
end
