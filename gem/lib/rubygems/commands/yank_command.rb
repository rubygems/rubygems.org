require 'rubygems/local_remote_options'
require 'rubygems/version_option'
require 'rubygems/gemcutter_utilities'

class Gem::Commands::YankCommand < Gem::Command
  include Gem::LocalRemoteOptions
  include Gem::VersionOption
  include Gem::GemcutterUtilities

  def description
    'Remove a specific gem version release from RubyGems.org'
  end

  def arguments
    "GEM       name of gem"
  end

  def usage
    "#{program_name} GEM -v VERSION [--platform PLATFORM] [--undo]"
  end
  
  def initialize
    super 'yank', description
    add_version_option("remove")
    add_platform_option("remove")
    add_option('--undo') do |value, options|
      options[:undo] = true
    end
  end

  def execute
    sign_in
    version = get_version_from_requirements(options[:version])
    require 'ap'
    ap options
    if !version.nil?
      if options[:undo]
        unyank_gem(version)
      else
        yank_gem(version)
      end
    else
      say "A version argument is required: #{usage}"
      terminate_interaction
    end
  end

  def yank_gem(version)
    say "Yanking gem from RubyGems.org..."
    yank_api_request(:delete, version, "api/v1/gems/yank")
  end
  
  def unyank_gem(version)
    say "Unyanking gem from RubyGems.org..."
    yank_api_request(:put, version, "api/v1/gems/unyank")
  end
  
  private
    def yank_api_request(method, version, api)
      name = get_one_gem_name
      response = rubygems_api_request(method, api) do |request|
        request.add_field("Authorization", Gem.configuration.rubygems_api_key)
        request.set_form_data({'gem_name' => name, 'version' => version})
      end
      say response.body
    end

    def get_version_from_requirements(requirements)
      begin
        requirements.requirements.first[1].version
      rescue
        nil
      end
    end
end
