class GeoipInfoResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :continent_code, as: :text
  field :country_code, as: :text
  field :country_code3, as: :text
  field :country_name, as: :text
  field :region, as: :text
  field :city, as: :text

  field :ip_addresses, as: :has_many
end
