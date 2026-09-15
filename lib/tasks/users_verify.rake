# frozen_string_literal: true

DAOMINR_STATUS_API = "https://api.domainr.com/v2/status"
AVAILABLE_STATUS = %w[inactive parked expiring deleting].freeze
ZONEDB_URL = "https://raw.githubusercontent.com/zonedb/zonedb/main/zones.txt"

EMAIL_DOMAIN_BOUNDARIES = [".", "@"].freeze

namespace :users do
  def find_unique_domains
    query = ["SELECT substring(users.email from '@(.*)$') as domain_name FROM users where email_confirmed='true' group by domain_name"]

    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    result = ActiveRecord::Base.connection.execute(sanitized_sql)
    result.map(&:values).flatten
  end

  def send_to_slack(_msg)
    # Rails.logger.info msg

    # slack_uri = URI(ENV["SLACK_HOOK"])
    # req = Net::HTTP::Post.new(slack_uri, "Content-Type" => "application/json")
    # req.body = { text: msg }.to_json

    # begin
    #   Net::HTTP.start(slack_uri.host, slack_uri.port, use_ssl: true) do |http|
    #     res = http.request(req)
    #     Rails.logger.info "slack response code: #{res.code} body: #{res.body}" unless res.is_a? Net::HTTPSuccess
    #   end
    # rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
    #   Rails.logger.info "could not send to slack. msg: #{msg} error: #{e}"
    # end

    nil
  end

  def no_mx_record?(domain, status)
    mx_records = Resolv::DNS.new.getresources(domain, Resolv::DNS::Resource::IN::MX).map { |r| r.exchange.to_s }
    return true if mx_records.empty?

    send_to_slack "please review domain: #{domain} status: #{status} mx: #{mx_records}"
    false
  rescue Resolv::ResolvError => e
    Rails.logger.info "ResolvError (#{e})"

    send_to_slack "please review domain: #{domain} status: #{status} mx: <failed>"
    false
  end

  def domain_available?(body, email_domain)
    json_body = JSON.parse(body)
    domain    = json_body.dig("status", 0, "domain")
    status    = json_body.dig("status", 0, "status")

    status&.split&.each do |item|
      next unless AVAILABLE_STATUS.include?(item) && no_mx_record?(email_domain, status)

      send_to_slack "domain: #{domain} is available for purchase with status: #{item}"
      return true
    end
    false
  end

  def block_users(domains)
    users = []
    domains.each do |domain|
      users += User.where("email ilike '%#{domain}'").select do |user|
        # email matches should be of the format subdomain.domain or @domain
        EMAIL_DOMAIN_BOUNDARIES.include? user.email.downcase.chomp(domain)[-1]
      end
    end

    if users.length <= 20
      users.each do |user|
        msg = "blocked user: #{user.display_handle} email: #{user.email} updated_at: #{user.updated_at} " \
              "gems: #{user.rubygems.count} total_downloads: #{user.total_downloads_count}"
        user.block!
        send_to_slack msg
      end
    else
      msg = "more than 10 user accounts with expired domains. please verify and block manually.
available_domains: #{domains}
"
      users.each do |user|
        user.rubygems_downloaded.first
        msg += "user: #{user.display_handle} email: #{user.email} updated_at: #{user.updated_at} " \
               "gems: #{user.rubygems.count} total_downloads: #{user.total_downloads_count}\n"
      end
      send_to_slack msg
    end
  end

  def zone_list
    zone_uri = URI(ZONEDB_URL)

    @zone_list ||= Net::HTTP.start(zone_uri.host, zone_uri.port, use_ssl: true) do |http|
      request   = Net::HTTP::Get.new zone_uri.request_uri
      response  = http.request request

      abort("zonedb request failed status: #{response.code} body: #{response.body}") unless response.is_a? Net::HTTPSuccess
      response.body.force_encoding("UTF-8").split("\n").reverse
    end
  end

  def find_root_domain(domain)
    zone_list.each do |zone|
      dot_zone = ".#{zone}"
      next unless domain.end_with? dot_zone

      root = domain.chomp(dot_zone).split(".").last.downcase
      return "#{root}#{dot_zone}"
    end
    domain
  end

  desc "Block users who have expired domain in their email"
  task verify: :environment do
    uri               = URI.parse(DAOMINR_STATUS_API)
    params            = { client_id: ENV["CLIENT_ID"] }
    retries           = 0
    available_domains = []

    begin
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        find_unique_domains.each do |domain|
          root_domain = find_root_domain(domain)

          params.merge!(domain: root_domain)
          uri.query = URI.encode_www_form(params)
          Rails.logger.info "checking domain: #{domain} root_domain: #{root_domain}"

          request   = Net::HTTP::Get.new uri.request_uri
          response  = http.request request

          if response.is_a? Net::HTTPSuccess
            Rails.logger.info response.body
            available = domain_available?(response.body, domain)
            available_domains << root_domain if available
          else
            msg = "API request for #{root_domain} failed with status: #{response.code} body: #{response.body}"
            send_to_slack msg
          end
        end
      end
    rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
      raise if (retries += 1) > 3

      Rails.logger.info "Timeout (#{e}), retrying in #{retries * 10} seconds"
      sleep(retries * 10)
      retry
    end

    block_users(available_domains)
  end
end
