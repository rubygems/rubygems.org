module RailsApplicationInstrumentation
  def self.instrument(label)
    if block_given?
      start = Time.now
      yield
      after_time = (Time.now - start) * 1_000
    end

    if after_time
      puts "[DEBUG_BOOT] #{label}: #{after_time.round(2)}ms" if ENV['DEBUG_BOOT']
    else
      puts "[DEBUG_BOOT] #{label}" if ENV['DEBUG_BOOT']
    end
  end

  class InitializerSubscriber
    attr_reader :events
    def initialize
      @events = []
    end

    def call(*args)
      event = ActiveSupport::Notifications::Event.new(*args)
      @events << [event.duration, event.payload[:initializer].to_s]
    end

    def total_time
      @events.sum(&:first)
    end
  end

  def self.included(base)
    config = base.config
    config.debug_boot = ENV['DEBUG_BOOT']

    if config.debug_boot
      subs = InitializerSubscriber.new
      ActiveSupport::Notifications.subscribe('load_config_initializer.railties', subs)

      config.after_initialize do
        puts "[DEBUG_BOOT] Slower initializers:"
        subs.events.sort_by { |i| -i.first }.take(5).each do |a|
          puts "[DEBUG_BOOT] #{a.last} loaded in #{a.first.round(2)}ms"
        end
        puts "[DEBUG_BOOT] Total time of initializers: #{subs.total_time.round(2)}ms"
      end

      base.prepend PrependMethods
    end
  end

  def initialize!
    RailsApplicationInstrumentation.instrument("Rails.initialize!") { super }
  end

  module PrependMethods
    def eager_load!
      RailsApplicationInstrumentation.instrument("Rails eager_load!") { super }
    end
  end
end
