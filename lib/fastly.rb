require 'net/http'

class Net::HTTP::Purge < Net::HTTPRequest
  METHOD = 'PURGE'.freeze
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end

class Fastly
  def self.purge(path, soft = false)
    return unless ENV['FASTLY_DOMAIN']
    domain = "https://#{ENV['FASTLY_DOMAIN']}/"
    headers = soft ? { 'Fastly-Soft-Purge' => 1 } : {}

    response = RestClient::Request.execute(method: :purge,
                                           url: domain + path,
                                           timeout: 10,
                                           headers: headers)
    json = JSON.parse(response)
    Rails.logger.debug "Fastly purge url=#{domain + path} status=#{json['status']} id=#{json['id']}"
    json
  end

  def self.purge_key(key, soft = false)
    headers = { 'Fastly-Key' => ENV['FASTLY_API_KEY'] }
    headers['Fastly-Soft-Purge'] = 1 if soft
    url = "https://api.fastly.com/service/#{ENV['FASTLY_SERVICE_ID']}/purge/#{key}"
    response = RestClient::Request.execute(method: :post,
                                           url: url,
                                           timeout: 10,
                                           headers: headers)
    json = JSON.parse(response)
    Rails.logger.debug "Fastly purge url=#{url} status=#{json['status']} id=#{json['id']}"
    json
  end

  def self.purge_api_cdn(gem_name)
    ["info/#{gem_name}", "versions", "names"].each do |path|
      purge path
    end
  end
end
