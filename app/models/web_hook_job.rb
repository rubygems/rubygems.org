class WebHookJob

  HTTP_ERRORS = [Timeout::Error,
                 Errno::EINVAL,
                 Errno::ECONNRESET,
                 EOFError,
                 Net::HTTPBadResponse,
                 Net::HTTPHeaderSyntaxError,
                 Net::ProtocolError]

  attr_reader :hook, :payload

  def initialize(hook, gem, host_with_port)
    @hook_id = hook.id
    version = gem.versions.latest
    @payload  = {
      'name'                    => gem.name,
      'version'                 => version.number,
      'rubyforge_project'       => version.rubyforge_project,
      'description'             => version.description,
      'summary'                 => version.summary,
      'authors'                 => version.authors,
      'downloads'               => gem.downloads,
      'project_uri'             => "http://#{host_with_port}/gems/#{gem.name}",
      'gem_uri'                 => "http://#{host_with_port}/gems/#{version.full_name}.gem"
    }.to_json
  end

  def hook
    # Storing a WebHook in an instance variable wasn't working (it wasn't deserializing correctly),
    # so I just store the ID, then do a lookup. 
    @hook ||= WebHook.find(@hook_id)
  end

  def perform
    RestClient.post(hook.url, payload, {'Content-Type' => 'application/json'})
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError]) => e
    hook.failure_count += 1
    hook.save!
  end

end
