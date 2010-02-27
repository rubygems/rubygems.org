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
    "#{program_name} GEM -v VERSION"
  end

  def initialize
    super 'yank', description
    add_version_option("remove")
  end

  def execute
    sign_in
    version = get_version_from_requirements(options[:version])
    if !version.nil?
      yank_gem(version)
    else
      say "A version argument is required: #{usage}"
      terminate_interaction
    end
  end

  def yank_gem(version)
    say "Yanking gem from RubyGems.org..."

    name = get_one_gem_name
    url = "api/v1/gems/yank"

    response = rubygems_api_request(:delete, url) do |request|
      request.add_field("Authorization", Gem.configuration.rubygems_api_key)
      request.set_form_data({'gem_name' => name, 'version' => version})
    end

    say response.body
  end
  
  private
    def get_version_from_requirements(requirements)
      begin
        requirements.requirements.first[1].version
      rescue
        nil
      end
    end
end
