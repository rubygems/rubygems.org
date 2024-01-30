FactoryBot.define do
  factory :ip_address do
    sequence(:ip_address) { |n| IPAddr.new(n, Socket::AF_INET6).to_s }
    geoip_info { nil }
  end
end
