class OIDC::AccessPolicy < OIDC::BaseModel
  class Statement < OIDC::BaseModel
    def match_jwt?(jwt)
      return unless principal.oidc == jwt[:iss]

      conditions.all? { _1.match?(jwt) }
    end

    class Principal < OIDC::BaseModel
      attribute :oidc, :string

      validates :oidc, presence: true
    end

    class Condition < OIDC::BaseModel
      def match?(jwt)
        claim_value = jwt[claim]
        case operator
        when "string_equals"
          value == claim_value
        when "string_matches"
          Regexp.new(value).match?(claim_value)
        else
          raise "Unknown operator #{operator.inspect}"
        end
      end

      attribute :operator, :string
      attribute :claim, :string
      attribute :value

      STRING_BOOLEAN_OPERATORS = %w[string_equals string_matches].freeze

      OPERATORS = STRING_BOOLEAN_OPERATORS

      validates :operator, presence: true, inclusion: { in: OPERATORS }
      validates :claim, presence: true
      validate :value_expected_type?

      def value_type
        case operator
        when *STRING_BOOLEAN_OPERATORS
          String
        when nil
          NilClass
        else
          raise "Unknown operator #{operator.inspect}"
        end
      end

      def value_expected_type?
        errors.add(:value, "must be #{value_type}") unless value.is_a?(value_type)
      end
    end

    EFFECTS = %w[allow deny].freeze

    attribute :effect, :string
    attribute :principal, Types::JsonDeserializable.new(Principal)
    attribute :conditions, Types::ArrayOf.new(Types::JsonDeserializable.new(Condition))

    validates :effect, presence: true, inclusion: { in: EFFECTS }

    validates :principal, presence: true, nested: true

    validates :conditions, nested: true
  end

  attribute :statements, Types::ArrayOf.new(Types::JsonDeserializable.new(Statement))

  validates :statements, presence: true, nested: true

  class AccessError < StandardError
  end

  def verify_access!(jwt)
    matching_statements = statements.select { _1.match_jwt?(jwt) }
    effect = matching_statements.last&.effect || "deny"

    case effect
    when "allow"
      # great, nothing to do. verified
      nil
    when "deny"
      raise AccessError
    else
      raise "Unhandled effect #{effect}"
    end
  end
end
