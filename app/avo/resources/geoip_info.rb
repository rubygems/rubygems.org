class Avo::Resources::GeoipInfo < Avo::BaseResource
  self.includes = []

  def fields
    field :continent_code, as: :text
    field :country_code, as: :text
    field :country_code3, as: :text
    field :country_name, as: :text
    field :region, as: :text
    field :city, as: :text

    field :ip_addresses, as: :has_many
  end
end
