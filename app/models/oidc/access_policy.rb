class OIDC::AccessPolicy < Dry::Struct
  transform_keys(&:to_sym)

  string_boolean_operators = Dry.Types::String.enum("string_equals", "string_regexp_match")
  numeric_boolean_operators = Dry.Types::String.enum("number_equals")
  unary_operators = Dry.Types::String.enum("is_null")
  Condition = Dry.Types::Hash.schema(
    operator: string_boolean_operators,
    claim: Dry.Types::String,
    value: Dry.Types::String
  ) | Dry.Types::Hash.schema(
    operator: numeric_boolean_operators,
    claim: Dry.Types::String,
    value: Dry.Types::Integer
  ) | Dry.Types::Hash.schema(
    operator: unary_operators,
    claim: Dry.Types::String
  )

  Schema = Dry::Schema.define do
    config.validate_keys = true

    #       statement {
    #         effect = "Allow"
    #
    #         principals {
    #           type        = "*"
    #           identifiers = ["*"]
    #         }
    #
    #         actions = [
    #           "ecr:GetDownloadUrlForLayer",
    #           "ecr:BatchGetImage",
    #           "ecr:BatchCheckLayerAvailability",
    #           "ecr:ListImages",
    #           "ecr:DescribeRepositories",
    #         ]
    #       }
    #
    #   assume_role_policy = jsonencode({
    #     Version = "2012-10-17"
    #     Statement = [
    #       {
    #         Effect = "Allow"
    #         Action = "sts:AssumeRoleWithWebIdentity"
    #         Principal = {
    #           Federated = aws_iam_openid_connect_provider.github-actions.arn
    #         }
    #         Condition = {
    #           StringEquals = {
    #             "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
    #           }
    #           StringLike = {
    #             "token.actions.githubusercontent.com:sub" : "repo:rubygems/rubygems.org:*"
    #           }
    #         }
    #       },
    #       {
    #         Effect = "Allow"
    #         Action = "sts:AssumeRole"
    #         Principal = {
    #           AWS = [
    #             for user in data.aws_iam_group.admins.users : user.arn
    #           ]
    #         }
    #       }
    #     ]
    #   })
    #
    required(:statements).filled.array(:hash) do
      required(:effect).value(Dry.Types::String.enum("allow"))
      required(:principal).hash do
        required(:oidc).value(Dry.Types::String.constrained(format: URI::DEFAULT_PARSER.make_regexp))
      end
      required(:conditions).array(Condition)
    end
  end

  class Contract < Dry::Validation::Contract
    json(Schema)
  end

  Dry::StructCompiler.add_attributes(struct: self, schema: Schema)
  transform_keys(&:to_sym)
  schema schema.lax

  include ActiveModel::Validations

  validate do
    Contract.new.call(as_json).errors.each do |error|
      attribute = error.path.map { |e| e.is_a?(Symbol) ? ".#{e}" : "[#{e}]" }.join.delete_prefix(".")
      errors.add(attribute, error.text)
    end
  end

  class Statement
    def match_jwt?(jwt)
      return unless principal.oidc == jwt[:iss]

      conditions.all? { _1.match?(jwt) }
    end

    class Condition
      def match?(jwt)
        claim_value = jwt[claim]
        case operator
        when "string_equals"
          value == claim_value
        else
          raise "Unknown operator #{operator.inspect}"
        end
      end
    end
  end

  class AccessError < StandardError
  end

  def verify_access!(jwt)
    effect = statements.select { _1.match_jwt?(jwt) }.last&.effect || "deny"

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
