require 'rubygems/local_remote_options'
require 'rubygems/gemcutter_utilities'

class Gem::Commands::YankCommand < Gem::Command
  include Gem::LocalRemoteOptions
  include Gem::GemcutterUtilities

  def description
    'Remove a specific gem version release from Gemcutter'
  end

  def arguments
    "GEM       name of gem"
  end

  def usage
    "#{program_name} GEM -v VERSION"
  end

  def initialize
    super 'yank', description
    add_option('-v', '--version VERSION', 'Version to remove') do |value, options|
      options[:version] = value
    end
  end

  def execute
    sign_in
    version = options[:version] #get_version_from_requirements(options[:version])
    if !version.nil?
      yank_gem(version)
    else
      say "A version argument is required: #{usage}"
    end
  end

  def yank_gem(version)
    say "Yanking gem from Gemcutter..."

    name = get_one_gem_name
    url = "api/v1/gems/#{name}/yank"
    # say "posting to #{url} w/ version '#{version}'"

    response = rubygems_api_request(:delete, url) do |request|
      request.add_field("Authorization", Gem.configuration.rubygems_api_key)
      request.set_form_data({'version' => version})
    end

    say response.body
  end

  # private
  #   def get_version_from_requirements(requirements)
  #     begin
  #       requirements.requirements.first[1].version
  #     rescue
  #       nil
  #     end
  #   end
end
