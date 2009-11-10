require 'rack'

class Rack::Maintenance

  attr_reader :app, :options

  def initialize(app, options={})
    @app     = app
    @options = options

    raise(ArgumentError, 'Must specify a :file') unless options[:file]
  end

  def call(env)
    if maintenance?
      data = File.read(file)
      [ 503, { 'Content-Type' => 'text/html', 'Content-Length' => data.length.to_s }, [data] ]
    else
      app.call(env)
    end
  end

private ######################################################################

  def environment
    options[:env]
  end

  def file
    options[:file]
  end

  def maintenance?
    environment ? ENV[environment] : File.exists?(file)
  end

end
