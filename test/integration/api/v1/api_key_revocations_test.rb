# frozen_string_literal: true

require "test_helper"

class Api::V1::ApiKeyRevocationsTest < ActionDispatch::IntegrationTest
  HEADER_KEYID = "GITHUB-PUBLIC-KEY-IDENTIFIER"
  HEADER_SIGNATURE = "GITHUB-PUBLIC-KEY-SIGNATURE"

  DEPS_DEV_HEADER_KEYID = "DepsDev-Public-Key-Identifier"
  DEPS_DEV_HEADER_SIGNATURE = "DepsDev-Public-Key-Signature"

  KEYS_RESPONSE_BODY =
    { "public_keys" => [

      "key_identifier" => "test_key_id",
      "is_current" => true

    ] }.freeze

  DENIED_REQUESTS = %i[missing_headers missing_key_id missing_signature unknown_key wrong_body
                       other_provider_key mixed_headers invalid_github_with_valid_deps_dev].freeze

  [
    [:github, HEADER_KEYID, HEADER_SIGNATURE, SecretScanning::GitHub::KEYS_URI],
    [:deps_dev, DEPS_DEV_HEADER_KEYID, DEPS_DEV_HEADER_SIGNATURE, SecretScanning::DepsDev::KEYS_URI]
  ].each do |name, header_keyid, header_signature, keys_uri|
    context "from #{name}" do
      context "on POST to revoke" do
        setup do
          key = OpenSSL::PKey::EC.generate("secp256k1")
          @private_key_pem = key.to_pem
          @public_key_pem = key.public_to_pem

          Rails.cache.delete(%w[GitHubSecretScanning public_keys test_key_id])
          Rails.cache.delete(["GitHubSecretScanning::DepsDev", "public_keys", "test_key_id"])

          h = KEYS_RESPONSE_BODY.dup
          h["public_keys"][0]["key"] = @public_key_pem

          stub_request(:get, keys_uri)
            .to_return(
              status: 200,
              headers: { "Content-Type" => "application/json" },
              body: h.to_json
            )

          @tokens = [
            "token" => "some_token", "type" => "some_type", "url" => "some_url"
          ]

          @user = create(:user)
        end

        DENIED_REQUESTS.each do |denial|
          should "reject #{denial} without changing keys, recording events, or sending mail" do
            logger = SemanticLogger::Test::CaptureLogEvents.new
            SecretScanning.stubs(:logger).returns(logger)
            api_key = create(:api_key, key: "leaked-token", owner: @user)
            unrelated_key = create(:api_key, owner: @user)
            key_state = [api_key, unrelated_key].map { |key| key.reload.attributes }
            body = JSON.dump([token: "leaked-token", type: "rubygems", url: "https://example.com/leak"])
            headers = { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)) }
            case denial
            when :missing_headers then headers.clear
            when :missing_key_id then headers.delete(header_keyid)
            when :missing_signature then headers.delete(header_signature)
            when :unknown_key then headers[header_keyid] = "unknown-key"
            when :wrong_body then body += "\n"
            when :other_provider_key
              other_provider = name == :github ? SecretScanning::DepsDev : SecretScanning::GitHub
              other_key = OpenSSL::PKey::EC.generate("prime256v1")
              stub_request(:get, other_provider::KEYS_URI).to_return(
                headers: { "Content-Type" => "application/json" },
                body: { public_keys: [key_identifier: "test_key_id", key: other_key.public_to_pem] }.to_json
              )
              other_provider.public_key("test_key_id")
              headers[header_signature] = Base64.strict_encode64(other_key.sign("SHA256", body))
            when :mixed_headers
              other_header = name == :github ? DEPS_DEV_HEADER_SIGNATURE : HEADER_SIGNATURE
              headers[other_header] = headers.delete(header_signature)
            when :invalid_github_with_valid_deps_dev
              [SecretScanning::GitHub, SecretScanning::DepsDev].each do |provider|
                stub_request(:get, provider::KEYS_URI).to_return(
                  headers: { "Content-Type" => "application/json" },
                  body: { public_keys: [key_identifier: "test_key_id", key: @public_key_pem] }.to_json
                )
              end
              headers = {
                HEADER_KEYID => "test_key_id", HEADER_SIGNATURE => Base64.strict_encode64(sign_body("wrong body")),
                DEPS_DEV_HEADER_KEYID => "test_key_id", DEPS_DEV_HEADER_SIGNATURE => Base64.strict_encode64(sign_body(body))
              }
            end

            assert_no_difference -> { @user.events.count } do
              assert_no_enqueued_jobs do
                assert_emails 0 do
                  post revoke_api_v1_api_key_path, params: body, headers: headers.merge("CONTENT_TYPE" => "application/json")
                end
              end
            end

            assert_response :unauthorized
            assert_equal(key_state, [api_key, unrelated_key].map { |key| key.reload.attributes })

            case denial
            when :unknown_key

              assert_equal "Secret scanning public key not found", response.body
            when :wrong_body, :other_provider_key, :invalid_github_with_valid_deps_dev

              assert_equal "Invalid secret scanning signature", response.body
            else
              assert_equal "Missing secret scanning signature", response.body
            end

            case denial
            when :wrong_body, :other_provider_key, :invalid_github_with_valid_deps_dev
              expected_provider = name == :github || denial == :invalid_github_with_valid_deps_dev ? "SecretScanning::GitHub" : "SecretScanning::DepsDev"
              event = logger.events.sole

              assert_equal :warn, event.level
              assert_equal "Invalid secret scanning signature", event.message
              assert_equal expected_provider, event.payload[:provider]
            end
          end
        end

        should "accept #{name} with an incomplete or invalid other provider signature" do
          api_key = create(:api_key, key: "leaked-token", owner: @user)
          body = JSON.dump([token: "leaked-token", type: "rubygems", url: "https://example.com/leak"])
          headers = { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)) }
          headers["Truffle-Public-Key-Identifier"] = "unknown-truffle-key"
          headers["Truffle-Public-Key-Signature"] = "invalid"
          if name == :github
            headers[DEPS_DEV_HEADER_KEYID] = "test_key_id"
            headers[DEPS_DEV_HEADER_SIGNATURE] = Base64.strict_encode64(sign_body("wrong body"))
          else
            headers[HEADER_KEYID] = "test_key_id"
          end

          assert_enqueued_emails 1 do
            post "/api/v1/api_key/revoke", params: body, headers: headers.merge("CONTENT_TYPE" => "application/json")
          end

          assert_response :success
          assert_equal "true_positive", response.parsed_body.sole.fetch("label")
          assert_predicate api_key.reload, :expired?
        end

        should "verify exact raw bytes and deduplicate using the last finding without touching unrelated keys" do
          api_key = create(:api_key, key: "leaked-token", owner: @user)
          unrelated_key = create(:api_key, owner: @user)
          unrelated_state = unrelated_key.reload.attributes
          findings = [
            { token: "leaked-token", type: "first", url: "https://example.com/first" },
            { token: "unknown-token", type: "unknown", url: "https://example.com/unknown" },
            { token: "leaked-token", type: "last", url: "https://example.com/last" }
          ]
          body = "#{JSON.pretty_generate(findings)}\n"

          assert_difference -> { @user.events.where(tag: Events::UserEvent::API_KEY_DELETED).count }, 1 do
            assert_emails 1 do
              perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
                post revoke_api_v1_api_key_path, params: body,
                  headers: { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)),
                             "CONTENT_TYPE" => "application/json" }
              end
            end
          end

          assert_response :success
          assert_equal [
            { "token_raw" => "leaked-token", "token_type" => "last", "label" => "true_positive" },
            { "token_raw" => "unknown-token", "token_type" => "unknown", "label" => "false_positive" }
          ], response.parsed_body
          assert_predicate api_key.reload, :expired?
          assert_equal unrelated_state, unrelated_key.reload.attributes
          assert_equal [@user.email], ActionMailer::Base.deliveries.sole.to
          assert_match "https://example.com/last", ActionMailer::Base.deliveries.sole.body.to_s
          refute_match "https://example.com/first", ActionMailer::Base.deliveries.sole.body.to_s
        end

        should "preserve already expired user keys without notifying again" do
          api_key = create(:api_key, key: "expired-token", owner: @user)
          api_key.update_column(:expires_at, 1.day.ago)
          key_state = api_key.reload.attributes
          body = JSON.dump([token: "expired-token", type: "rubygems", url: "https://example.com/leak"])

          assert_no_difference -> { @user.events.count } do
            assert_no_enqueued_emails do
              post revoke_api_v1_api_key_path, params: body,
                headers: { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)),
                           "CONTENT_TYPE" => "application/json" }
            end
          end

          assert_response :success
          assert_equal "true_positive", response.parsed_body.sole.fetch("label")
          assert_equal key_state, api_key.reload.attributes
        end

        should "expire trusted publisher keys without emailing and preserve their classification" do
          api_key = create(:api_key, :trusted_publisher, key: "publisher-token")
          body = JSON.dump([token: "publisher-token", type: "rubygems", url: "https://example.com/leak"])

          assert_no_enqueued_emails do
            post revoke_api_v1_api_key_path, params: body,
              headers: { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)),
                         "CONTENT_TYPE" => "application/json" }
          end

          assert_response :success
          assert_equal "true_positive", response.parsed_body.sole.fetch("label")
          assert_predicate api_key.reload, :expired?
        end

        should "preserve numeric-token error precedence without side effects" do
          api_key = create(:api_key, key: "leaked-token", owner: @user)
          unrelated_key = create(:api_key, owner: @user)
          key_state = [api_key, unrelated_key].map { |key| key.reload.attributes }
          body = JSON.dump([{ token: "leaked-token" }, { token: 42 }, { type: "missing-token" }])

          assert_no_difference -> { @user.events.count } do
            assert_no_enqueued_jobs do
              assert_emails 0 do
                assert_raises(TypeError) do
                  post revoke_api_v1_api_key_path, params: body,
                    headers: { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)),
                               "CONTENT_TYPE" => "application/json" }
                end
              end
            end
          end

          assert_equal(key_state, [api_key, unrelated_key].map { |key| key.reload.attributes })
        end

        should "validate all findings before expiring any keys" do
          api_key = create(:api_key, key: "leaked-token", owner: @user)
          body = JSON.dump([{ token: "leaked-token" }, { token: "" }, { token: 42 }])

          assert_no_difference -> { @user.events.count } do
            assert_no_enqueued_jobs do
              post revoke_api_v1_api_key_path, params: body,
                headers: { header_keyid => "test_key_id", header_signature => Base64.strict_encode64(sign_body(body)),
                           "CONTENT_TYPE" => "application/json" }
            end
          end

          assert_response :bad_request
          refute_predicate api_key.reload, :expired?
        end

        context "with no key_id" do
          setup do
            post revoke_api_v1_api_key_path(@rubygem),
              params: {},
              headers: { header_signature => "bar" }
          end

          should "deny access" do
            assert_response :unauthorized
            assert_equal "Missing secret scanning signature", @response.body
          end
        end

        context "with no signature" do
          setup do
            post revoke_api_v1_api_key_path(@rubygem),
              params: {},
              headers: { header_keyid => "foo" }
          end

          should "deny access" do
            assert_response :unauthorized
            assert_equal "Missing secret scanning signature", @response.body
          end
        end

        context "with invalid key_id" do
          setup do
            post revoke_api_v1_api_key_path(@rubygem),
              params: {},
              headers: { header_keyid => "foo", header_signature => "bar" }
          end

          should "deny access" do
            assert_response :unauthorized
            assert_equal "Secret scanning public key not found", @response.body
          end
        end

        context "with invalid signature" do
          setup do
            key = "rubygems_#{SecureRandom.hex(24)}"
            @api_key = create(:api_key, key: key)
            @tokens << { "token" => key, "type" => "rubygems", "url" => "some_url" }
            signature = sign_body("Hello world!")

            assert_no_enqueued_emails do
              assert_no_difference -> { @api_key.user.events.count } do
                post revoke_api_v1_api_key_path(@rubygem),
                  params: @tokens,
                  headers: { header_keyid => "test_key_id", header_signature => Base64.encode64(signature) },
                  as: :json
              end
            end
          end

          should "deny access" do
            assert_response :unauthorized
            assert_equal "Invalid secret scanning signature", @response.body
            assert_nil @api_key.reload.expires_at
          end
        end

        context "without a valid token" do
          setup do
            signature = sign_body(JSON.dump(@tokens))
            post revoke_api_v1_api_key_path(@rubygem),
              params: @tokens,
              headers: { header_keyid => "test_key_id", header_signature => Base64.encode64(signature) },
              as: :json
          end

          should "returns success" do
            assert_response :success
            json = JSON.parse(@response.body)[0]

            assert_equal "false_positive", json["label"]
            assert_equal @tokens[0]["type"], json["token_type"]
            assert_equal @tokens[0]["token"], json["token_raw"]
          end
        end

        context "with a valid token" do
          setup do
            key = "rubygems_#{SecureRandom.hex(24)}"
            @api_key = create(:api_key, key: key)
            @tokens << { "token" => key, "type" => "rubygems", "url" => "some_url" }
            signature = sign_body(JSON.dump(@tokens))

            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              post revoke_api_v1_api_key_path(@rubygem),
                params: @tokens,
                headers: { header_keyid => "test_key_id", header_signature => Base64.encode64(signature) },
                as: :json
            end
          end

          should "returns success and remove the token" do
            assert_response :success

            json = JSON.parse(@response.body)

            assert_equal "true_positive", json.last["label"]
            assert_equal @tokens.last["token"], json.last["token_raw"]

            assert_predicate @api_key.reload, :expired?
          end

          should "delivers an email" do
            refute_empty ActionMailer::Base.deliveries
            email = ActionMailer::Base.deliveries.last

            assert_equal [@api_key.user.email], email.to
            assert_equal ["no-reply@mailer.rubygems.org"], email.from
            assert_equal "One of your API keys was revoked on rubygems.org", email.subject
            assert_match "some_url", email.body.to_s
          end

          should "not revoke or notify again when the token is reported at another URL" do
            expires_at = @api_key.reload.expires_at
            event_count = @api_key.user.events.count
            @tokens.last["url"] = "another_url"
            signature = sign_body(JSON.dump(@tokens))

            travel 1.hour do
              assert_no_enqueued_emails do
                post revoke_api_v1_api_key_path,
                  params: @tokens,
                  headers: { header_keyid => "test_key_id", header_signature => Base64.encode64(signature) },
                  as: :json
              end
            end

            assert_response :success
            assert_equal "true_positive", response.parsed_body.last["label"]
            assert_equal expires_at, @api_key.reload.expires_at
            assert_equal event_count, @api_key.user.events.count
          end
        end
      end
    end
  end

  context "from Truffle" do
    setup do
      @truffle_key = OpenSSL::PKey::EC.generate("prime256v1")
      @truffle_config = Rails.configuration.secret_scanning.fetch(:truffle, {})
      @original_truffle_config = @truffle_config.dup
      @truffle_config.merge!(key_identifier: "test-truffle-key", public_key: @truffle_key.public_to_pem)
      @user = create(:user)
      @api_key = create(:api_key, key: "leaked-token", owner: @user)
      @unrelated_key = create(:api_key, owner: @user)
      @finding = { id: "finding-1", token: "leaked-token", type: "RubyGems", url: "https://example.com/leak", source: "Github" }
    end

    teardown do
      @truffle_config.replace(@original_truffle_config)
    end

    should "authenticate P-256 signed raw bytes and revoke without classification feedback" do
      body = "#{JSON.pretty_generate([@finding])}\n"

      assert_difference -> { @user.events.where(tag: Events::UserEvent::API_KEY_DELETED).count }, 1 do
        assert_emails 1 do
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            post_truffle(body)
          end
        end
      end

      assert_response :no_content
      assert_empty response.body
      assert_predicate @api_key.reload, :expired?
      refute_predicate @unrelated_key.reload, :expired?
      assert_equal [@user.email], ActionMailer::Base.deliveries.sole.to
      assert_match @finding[:url], ActionMailer::Base.deliveries.sole.body.to_s
    end

    %i[missing_headers missing_identifier missing_signature unknown_identifier unconfigured_key altered_bytes wrong_key malformed_signature
       mixed_headers invalid_github invalid_deps_dev unauthenticated_malformed_json].each do |denial|
      should "deny #{denial} without mutations, events, jobs, or emails" do
        body = JSON.pretty_generate([@finding])
        headers = {}
        case denial
        when :missing_headers
          headers = { "Truffle-Public-Key-Identifier" => nil, "Truffle-Public-Key-Signature" => nil }
        when :missing_identifier then headers["Truffle-Public-Key-Identifier"] = nil
        when :missing_signature then headers["Truffle-Public-Key-Signature"] = nil
        when :unknown_identifier then headers["Truffle-Public-Key-Identifier"] = "unknown"
        when :unconfigured_key then @truffle_config[:public_key] = nil
        when :altered_bytes
          headers["Truffle-Public-Key-Signature"] = Base64.strict_encode64(@truffle_key.sign("SHA256", JSON.dump([@finding])))
        when :wrong_key
          headers["Truffle-Public-Key-Signature"] = Base64.strict_encode64(OpenSSL::PKey::EC.generate("prime256v1").sign("SHA256", body))
        when :malformed_signature then headers["Truffle-Public-Key-Signature"] = "not-base64!"
        when :unauthenticated_malformed_json
          body = '[{"token":'
          headers["Truffle-Public-Key-Signature"] = Base64.strict_encode64(@truffle_key.sign("SHA256", "different bytes"))
        when :mixed_headers
          headers = { "Truffle-Public-Key-Signature" => nil, HEADER_SIGNATURE => Base64.strict_encode64(@truffle_key.sign("SHA256", body)) }
        when :invalid_github, :invalid_deps_dev
          provider = denial == :invalid_github ? SecretScanning::GitHub : SecretScanning::DepsDev
          headers = { provider::IDENTIFIER_HEADER => "test_key_id", provider::SIGNATURE_HEADER => "invalid" }
          Rails.cache.delete([provider::CACHE_NAMESPACE, "public_keys", "test_key_id"])
          stub_request(:get, provider::KEYS_URI).to_return(
            headers: { "Content-Type" => "application/json" },
            body: { public_keys: [key_identifier: "test_key_id", key: @truffle_key.public_to_pem] }.to_json
          )
        end

        assert_truffle_no_side_effects do
          post_truffle(body, headers:)
        end

        assert_response :unauthorized
      end
    end

    should "accept Truffle when earlier providers have incomplete headers" do
      post_truffle(JSON.dump([@finding]), headers: { HEADER_KEYID => "incomplete", DEPS_DEV_HEADER_SIGNATURE => "incomplete" })

      assert_response :no_content
      assert_predicate @api_key.reload, :expired?
    end

    [nil, "", "   ", 42, false, [], {}].product(%w[id token type url source]).each do |invalid, field|
      should "reject #{field} of #{invalid.inspect} before revoking any finding" do
        finding = @finding.merge(field.to_sym => invalid)
        finding.delete(field.to_sym) if invalid.nil?

        assert_truffle_no_side_effects { post_truffle(JSON.dump([@finding, finding])) }

        assert_response :bad_request
      end
    end

    should "reject non-array payloads and non-object findings" do
      [@finding, { _json: [@finding] }, nil, "finding", [@finding, nil], [@finding, "finding"]].each do |payload|
        assert_truffle_no_side_effects { post_truffle(JSON.dump(payload)) }

        assert_response :bad_request
      end
    end

    should "reject malformed JSON without side effects" do
      assert_truffle_no_side_effects { post_truffle('[{"token":') }

      assert_response :bad_request
    end

    should "acknowledge an empty batch without side effects" do
      assert_truffle_no_side_effects { post_truffle("[]") }

      assert_response :no_content
      assert_empty response.body
    end

    should "expire trusted publisher keys without jobs or emails" do
      publisher_key = create(:api_key, owner: create(:oidc_trusted_publisher_github_action), key: "publisher-token")

      assert_no_difference -> { @user.events.count } do
        assert_no_enqueued_jobs do
          assert_emails 0 do
            post_truffle(JSON.dump([@finding.merge(token: "publisher-token")]))
          end
        end
      end

      assert_response :no_content
      assert_empty response.body
      assert_predicate publisher_key.reload, :expired?
      refute_predicate @api_key.reload, :expired?
    end

    should "deduplicate by token and acknowledge retries without revoking or notifying again" do
      body = JSON.dump([@finding, @finding.merge(id: "finding-2", url: "https://example.com/last"), @finding.merge(token: "unknown")])
      unrelated_state = @unrelated_key.reload.attributes

      assert_difference -> { @user.events.where(tag: Events::UserEvent::API_KEY_DELETED).count }, 1 do
        assert_emails 1 do
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            post_truffle(body)
          end
        end
      end

      assert_response :no_content
      assert_empty response.body
      assert_predicate @api_key.reload, :expired?
      assert_equal unrelated_state, @unrelated_key.reload.attributes
      assert_match "https://example.com/last", ActionMailer::Base.deliveries.sole.body.to_s

      travel 1.hour do
        assert_truffle_no_side_effects { post_truffle(body) }
      end

      assert_response :no_content
      assert_empty response.body
    end
  end

  private

  def post_truffle(body, headers: {})
    post revoke_api_v1_api_key_path, params: body, headers: {
      "CONTENT_TYPE" => "application/json",
      "Truffle-Public-Key-Identifier" => "test-truffle-key",
      "Truffle-Public-Key-Signature" => Base64.strict_encode64(@truffle_key.sign("SHA256", body))
    }.merge(headers)
  end

  def assert_truffle_no_side_effects(&block)
    state = [@api_key, @unrelated_key].map { |key| key.reload.attributes }
    assert_no_difference -> { @user.events.count } do
      assert_no_enqueued_jobs do
        assert_emails(0, &block)
      end
    end

    assert_equal(state, [@api_key, @unrelated_key].map { |key| key.reload.attributes })
  end

  def sign_body(body)
    private_key = OpenSSL::PKey::EC.new(@private_key_pem)
    private_key.sign(OpenSSL::Digest.new("SHA256"), body)
  end
end
