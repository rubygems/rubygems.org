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
      # Ruby memoizes most catastrophic patterns, but one using a backreference
      # or a lookahead still backtracks without bound, and a claim is matched on
      # a request thread with nothing else to stop it.
      MATCH_TIMEOUT = 0.5

      def match?(jwt)
        claim_value = jwt[claim]
        case operator
        when "string_equals"
          value == claim_value
        when "string_matches"
          # A claim is only ever matched as a string: Regexp#match? raises on an
          # Integer or an Array, and a numeric claim like `iat` is advertised by
          # the providers, so a condition could be written against one.
          return false unless claim_value.is_a?(String)

          begin
            matcher.match?(claim_value)
          rescue Regexp::TimeoutError
            # Denying is the safe answer, and the policy is still too expensive
            # to evaluate, so say so.
            logger.warn("Condition timed out", claim:, value:)
            false
          end
        else
          raise "Unknown operator #{operator.inspect}"
        end
      end

      # Anchored: the pattern has to describe the whole claim, not merely occur
      # somewhere in it. Grouped so that a top level alternation in the pattern
      # cannot escape the anchors.
      #
      # Built in one place because the wrapping decides what compiles: a value
      # ending in a backslash is invalid on its own and invalid wrapped, but for
      # a different reason, so validating the bare value could disagree with
      # what is matched.
      def matcher
        Regexp.new("\\A(?:#{value})\\z", timeout: MATCH_TIMEOUT)
      end

      attribute :operator, :string
      attribute :claim, :string
      attribute :value

      STRING_BOOLEAN_OPERATORS = %w[string_equals string_matches].freeze

      OPERATORS = STRING_BOOLEAN_OPERATORS

      validates :operator, presence: true, inclusion: { in: OPERATORS }
      validates :claim, presence: true
      validate :value_expected_type?
      validate :value_compiles, if: -> { operator == "string_matches" && value.is_a?(String) }

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

      # Without this an unparseable pattern saves and only fails when a token is
      # exchanged, where it raises rather than denying, so the role stops
      # working with no sign of why.
      def value_compiles
        matcher
      rescue RegexpError => e
        errors.add(:value, "is not a valid regular expression: #{e.message.lines.first.strip}")
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
