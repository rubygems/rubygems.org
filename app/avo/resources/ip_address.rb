class Avo::Resources::IpAddress < Avo::BaseResource
  self.title = :ip_address
  self.includes = []

  search[:hide_on_global] = true
  search[:query] = lambda {
    query.where("ip_address <<= inet ?", params[:q])
  }

  def fields
    field :id, as: :id

    field :ip_address, as: :text
    field :hashed_ip_address, as: :textarea
    field :geoip_info, as: :json_viewer

    tabs style: :pills do
      field :user_events, as: :has_many
      field :rubygem_events, as: :has_many
    end
  end
end
