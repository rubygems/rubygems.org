class OIDC::ApiKeyPermissions < Dry::Struct
  def create_params(user)
    params = scopes.map(&:to_sym).index_with(true)
    params[:ownership] = gems&.sole&.then { user.ownerships.find_by!(rubygem: { name: _1 }) }
    params[:expires_at] = DateTime.now.utc + Schema.types[:valid_for][valid_for || Dry::Types::Undefined]
    params
  end

  transform_keys(&:to_sym)

  Schema = Dry::Schema.define do
    config.validate_keys = true
    duration = Dry.Types().Nominal(ActiveSupport::Duration).constructor do |value|
      case value
      when String
        ActiveSupport::Duration.parse(value)
      when Integer
        ActiveSupport::Duration.build(value)
      when ActiveSupport::Duration
        value
      else
        raise TypeError, "#{value.inspect} cannot be coerced to a duration"
      end
    end
    required(:scopes).filled(
      Dry.Types.Array(Dry.Types()::String.enum(*ApiKey::API_SCOPES.map(&:to_s)))
    )
    optional(:valid_for).filled(duration.default(30.minutes.freeze), lteq?: 1.day, gteq?: 5.minutes)
    optional(:gems).maybe(
      Dry.Types.Array(
        Dry.Types::String.constrained(format: Rubygem::NAME_PATTERN)
      )
        .constrained(filled: true)
      # .constrained(max_size: 1)
    )
  end

  class Contract < Dry::Validation::Contract
    json(Schema) do
      config.validate_keys = true
    end

    rule(:scopes) do
      key.failure("show_dashboard is exclusive") if value.include?("show_dashboard") && value.size > 1
      key.failure("must be unique") if value.dup.uniq!
    end
  end

  Dry::StructCompiler.add_attributes(struct: self, schema: Schema)

  schema schema.lax

  include ActiveModel::AttributeAssignment

  include ActiveModel::Validations
end
