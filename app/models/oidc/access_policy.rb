# frozen_string_literal: true

class OIDC::AccessPolicy < ApplicationModel
  MAX_STATEMENTS = 5
  MAX_TOTAL_CONDITIONS = 10

  class Statement < ApplicationModel
    def match_jwt?(jwt)
      return false unless principal.oidc == jwt[:iss]

      conditions.all? { it.match?(jwt) }
    end

    class Principal < ApplicationModel
      attribute :oidc, :string

      validates :oidc, presence: true
    end

    class Condition < ApplicationModel
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
        else
          NilClass
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

    validates :conditions, nested: true, presence: true

    def conditions_attributes=(attributes)
      self.conditions = attributes.map { Condition.new(_2) }
    end
  end

  attribute :statements, Types::ArrayOf.new(Types::JsonDeserializable.new(Statement))

  validates :statements, presence: true, nested: true
  validate :validate_complexity

  def statements_attributes=(attributes)
    self.statements = attributes.map { Statement.new(_2) }
  end

  class AccessError < StandardError
  end

  def verify_access!(jwt)
    raise AccessError, "denying due to policy exceeding complexity limits" unless complexity_within_limits?

    matching_statements = statements.select { it.match_jwt?(jwt) }
    raise AccessError, "denying due to no matching statements" if matching_statements.empty?

    case (effect = matching_statements.last.effect)
    when "allow"
      # great, nothing to do. verified
      nil
    when "deny"
      raise AccessError, "explicit denial from #{matching_statements.last.as_json}"
    else
      raise "Unhandled effect #{effect}"
    end
  end

  private

  def validate_complexity
    return if complexity_within_limits?

    errors.add(:statements, :too_complex, max_statements: MAX_STATEMENTS, max_conditions: MAX_TOTAL_CONDITIONS)
  end

  def complexity_within_limits?
    policy_statements = Array(statements)
    policy_statements.size <= MAX_STATEMENTS &&
      policy_statements.sum { Array(it.conditions).size } <= MAX_TOTAL_CONDITIONS
  end
end
