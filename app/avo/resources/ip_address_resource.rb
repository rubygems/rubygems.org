class IpAddressResource < Avo::BaseResource
  self.title = :ip_address
  self.includes = []

  self.hide_from_global_search = true
  self.search_query = lambda {
    scope.where("ip_address <<= inet ?", params[:q])
  }

  field :id, as: :id

  field :ip_address, as: :text
  field :hashed_ip_address, as: :textarea
  field :geoip_info, as: :json_viewer

  tabs style: :pills do
    field :user_events, as: :has_many
    field :rubygem_events, as: :has_many
  end
end
