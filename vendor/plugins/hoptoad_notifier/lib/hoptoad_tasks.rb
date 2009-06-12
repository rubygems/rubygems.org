require 'net/http'
require 'uri'
require 'active_support'

module HoptoadTasks
  def self.deploy(opts = {})
    if HoptoadNotifier.api_key.blank?
      puts "I don't seem to be configured with an API key.  Please check your configuration."
      return false
    end

    if opts[:rails_env].blank?
      puts "I don't know to which Rails environment you are deploying (use the TO=production option)."
      return false
    end

    params = {:api_key => HoptoadNotifier.api_key}
    opts.each {|k,v| params["deploy[#{k}]"] = v }

    url = URI.parse("http://#{HoptoadNotifier.host}/deploys.txt")
    response = Net::HTTP.post_form(url, params)
    puts response.body
    return Net::HTTPSuccess === response
  end
end

