FactoryBot.define do
  factory :oidc_provider, class: "OIDC::Provider" do
    sequence(:issuer) { |n| "https://#{n}.token.actions.githubusercontent.com" }
    configuration do
      {
        issuer: issuer,
        jwks_uri: "#{issuer}/.well-known/jwks",
        subject_types_supported: %w[
          public
          pairwise
        ],
        response_types_supported: [
          "id_token"
        ],
        claims_supported: %w[
          sub
          aud
          exp
          iat
          iss
          jti
          nbf
          ref
          repository
          repository_id
          repository_owner
          repository_owner_id
          run_id
          run_number
          run_attempt
          actor
          actor_id
          workflow
          workflow_ref
          workflow_sha
          head_ref
          base_ref
          event_name
          ref_type
          environment
          environment_node_id
          job_workflow_ref
          job_workflow_sha
          repository_visibility
          runner_environment
        ],
        id_token_signing_alg_values_supported: [
          "RS256"
        ],
        scopes_supported: [
          "openid"
        ]
      }
    end
    jwks do
      {
        keys: [
          pkey&.to_jwk
        ].compact
      }
    end

    transient do
      pkey { OpenSSL::PKey::RSA.generate(2048) }
    end

    trait :buildkite do
      sequence(:issuer) { |n| "https://#{n}.agent.buildkite.com" }
      configuration do
        {
          issuer: issuer,
          jwks_uri: "#{issuer}/.well-known/jwks",
          id_token_signing_alg_values_supported: [
            "RS256"
          ],
          response_types_supported: [
            "id_token"
          ],
          scopes_supported: [
            "openid"
          ],
          subject_types_supported: %w[
            public
            pairwise
          ],
          claims_supported: %w[
            sub
            aud
            exp
            iat
            iss
            nbf
            jti
            organization_id
            organization_slug
            pipeline_id
            pipeline_slug
            build_number
            build_branch
            build_tag
            build_commit
            build_source
            step_key
            job_id
            agent_id
            cluster_id
            cluster_name
            queue_id
            queue_key
            runner_environment
          ]
        }
      end
    end

    factory :oidc_provider_buildkite, traits: [:buildkite]
  end
end
