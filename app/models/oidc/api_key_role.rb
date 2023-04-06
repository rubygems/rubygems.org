class OIDC::ApiKeyRole < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: "oidc_provider_id"
  belongs_to :user

  Dry::Schema.load_extensions(:hints)

  class ApiKeyPermissions < Dry::Struct
    def create_params(user)
      params = scopes.map(&:to_sym).index_with(true)
      params[:ownership] = gems&.sole&.then { user.ownerships.find_by!(rubygem: { name: _1 }) }
      params
    end

    transform_keys(&:to_sym)
    Schema = Dry::Schema.define do
      config.validate_keys = true
      Duration = Dry.Types().Nominal(ActiveSupport::Duration).constructor do |value|
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
      optional(:valid_for).value(Duration.default(30.minutes.freeze), lteq?: 1.day, gteq?: 5.minutes)
      optional(:gems).maybe(Dry.Types.Array(Dry.Types::String.constrained(format: Rubygem::NAME_PATTERN)).constrained(filled: true))
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
    include ActiveModel::Validations

    validate do
      Contract.new.call(attributes).errors.each do |e|
        errors.add(e.path.map { |e| e.is_a?(Symbol) ? ".#{e}" : "[#{e}]" }.join.delete_prefix("."), e.text)
      end
    end
  end

  attribute :api_key_permissions, (Class.new(ActiveRecord::Type::Json) do
    def deserialize(value)
      ApiKeyPermissions.new(super)
    end
  end).new
  validates :api_key_permissions, presence: true, nested: true
  validate :gems_belong_to_user

  def gems_belong_to_user
    Array.wrap(api_key_permissions.gems).each_with_index do |name, idx|
      errors.add("api_key_permissions.gems[#{idx}]", "(#{name}) does not belong to user #{user.display_handle}") if user.rubygems.where(name:).empty?
    end
  end

  class AccessPolicy < Dry::Struct
    transform_keys(&:to_sym)
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
        # optional(:conditions).array(:hash) do
        #   required(:string_equals) do
        #   end
        # end
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
      Contract.new.call(as_json).errors.each do |e|
        errors.add(e.path.map { |e| e.is_a?(Symbol) ? ".#{e}" : "[#{e}]" }.join.delete_prefix("."), e.text)
      end
    end

    class Statement
      def match_jwt?(jwt)
        return unless principal.oidc == jwt[:iss]

        # TODO: all conditions match
        # conditions.all? { _1.match?(jwt) }

        true
      end
    end

    def verify_access!(jwt)
      effects = statements.filter_map do |statement|
        statement.effect if statement.match_jwt?(jwt)
      end.uniq

      case effects
      when %w[allow]
        # great, nothing to do. verified
      when []
        raise "No matching statements"
      else
        raise "Unhandled effect"
      end
    end
  end

  attribute :access_policy, (Class.new(ActiveRecord::Type::Json) do
    def deserialize(value)
      AccessPolicy.new(super)
    end
  end).new
  validates :access_policy, presence: true, nested: { a: :b }
end
