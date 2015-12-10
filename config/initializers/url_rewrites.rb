ALLOWED_HOSTS = [Gemcutter::HOST, 'index.rubygems.org', 'fastly.rubygems.org', 'docs.rubygems.org']

Rails.application.configure do |config|
  config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
    r301 %r{/api(.*)}, "#{Gemcutter::HOST}$&",
      if: proc { |rack_env| !ALLOWED_HOSTS.include?(rack_env['SERVER_NAME']) }
    r301 %r{/(book|chapter|export|read|shelf|syndicate)(.*)}, "http://docs.rubygems.org/$1$2",
      if: proc { |rack_env| rack_env['SERVER_NAME'] !~ /docs/ }
    r301 %r{/pages/gem_docs$}, "http://guides.rubygems.org/command-reference"
    r301 %r{/pages/api_docs$}, "http://guides.rubygems.org/rubygems-org-api"
  end
end
