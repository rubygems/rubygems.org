class GeoipInfo < OIDC::BaseModel
  attribute :continent_code, :string
  attribute :country_code, :string
  attribute :country_code3, :string
  attribute :country_name, :string
  attribute :region, :string
  attribute :city, :string

  def to_s
    parts = [city&.titleize, region&.upcase, country_code&.upcase].compact
    if !parts.empty?
      parts.join(", ")
    elsif country_name
      country_name
    else
      "Unknown"
    end
  end
end
