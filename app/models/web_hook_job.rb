class WebHookJob

  HTTP_ERRORS = [Timeout::Error,
                 Errno::EINVAL,
                 Errno::ECONNRESET,
                 EOFError,
                 Net::HTTPBadResponse,
                 Net::HTTPHeaderSyntaxError,
                 Net::ProtocolError]

  attr_reader :hook, :payload

  def initialize(hook, gem)
    @hook = hook
    version = gem.versions.latest
    @payload  = {
      'name'                    => gem.name,
      'version'                 => version.number,
      'rubyforge_project'       => version.rubyforge_project,
      'description'             => version.description,
      'summary'                 => version.summary,
      'authors'                 => version.authors,
      'downloads'               => gem.downloads
    }.to_json
  end

  def perform
    RestClient.post(@hook.url, payload, {'Content-Type' => 'application/json'})
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError]) => e
    hook.failure_count += 1
    hook.save!
  end

end
