require "application_system_test_case"

class Avo::OIDCProvidersSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "1",
      credentials: {
        token: user.oauth_token,
        expires: false
      },
      info: {
        name: user.login
      }
    )

    stub_github_info_request(user.info_data)

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end

  test "refreshing provider" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com", configuration: nil, jwks: nil)

    visit avo.resources_oidc_provider_path(provider)
    click_button "Actions"
    click_on "Refresh OIDC Provider"

    stub_request(:get, "https://token.actions.githubusercontent.com/.well-known/openid-configuration").to_return(
      status: 200,
      body: {
        issuer: "https://token.actions.githubusercontent.com",
        jwks_uri: "https://token.actions.githubusercontent.com/.well-known/jwks",
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
      }.to_json,
      headers: {
        "content-type" => "application/json; charset=utf-8"
      }
    )
    stub_request(:get, "https://token.actions.githubusercontent.com/.well-known/jwks").to_return(
      status: 200,
      body: {
        keys: [
          {
            n: "4WpHpoBYsVBVfSlfgnRbdPMxP3Eb7rFqE48e4pPM4qH_9EsUZIi21LjOu8UkKn14L4hrRfzfRHG7VQSbxXBU1Qa-xM5yVxdmfQZKBxQnPWaE1v7edjxq1ZYnqHIp90Uvn" \
               "w6798xMCSvI_V3FR8tix5GaoTgkixXlPc-ozifMyEZMmhvuhfDsSxQeTSHGPlWfGkX0id_gYzKPeI69EGtQ9ZN3PLTdoAI8jxlQ-jyDchi9h2ax6hgMLDsMZyiIXnF2UY" \
               "q4j36Cs5RgdC296d0hEOHN0WYZE-xPl7y_A9UHcVjrxeGfVOuTBXqjowofimn4ESnVXNReCsOwZCJlvJzfpQ",
            kty: "RSA",
            kid: "78167F727DEC5D801DD1C8784C704A1C880EC0E1",
            alg: "RS256",
            e: "AQAB",
            use: "sig",
            x5c: [
              "MIIDrDCCApSgAwIBAgIQMPdKi0TFTMqmg1HHo6FfsDANBgkqhkiG9w0BAQsFADA2MTQwMgYDVQQDEyt2c3RzLXZzdHNnaHJ0LWdoLXZzby1vYXV0aC52aXN1YWxzdHVkaW8" \
              "uY29tMB4XDTIyMDEwNTE4NDcyMloXDTI0MDEwNTE4NTcyMlowNjE0MDIGA1UEAxMrdnN0cy12c3RzZ2hydC1naC12c28tb2F1dGgudmlzdWFsc3R1ZGlvLmNvbTCCASIwDQ" \
              "YJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOFqR6aAWLFQVX0pX4J0W3TzMT9xG+6xahOPHuKTzOKh//RLFGSIttS4zrvFJCp9eC+Ia0X830Rxu1UEm8VwVNUGvsTOclcXZ" \
              "n0GSgcUJz1mhNb+3nY8atWWJ6hyKfdFL58Ou/fMTAkryP1dxUfLYseRmqE4JIsV5T3PqM4nzMhGTJob7oXw7EsUHk0hxj5VnxpF9Inf4GMyj3iOvRBrUPWTdzy03aACPI8Z" \
              "UPo8g3IYvYdmseoYDCw7DGcoiF5xdlGKuI9+grOUYHQtvendIRDhzdFmGRPsT5e8vwPVB3FY68Xhn1TrkwV6o6MKH4pp+BEp1VzUXgrDsGQiZbyc36UCAwEAAaOBtTCBsjA" \
              "OBgNVHQ8BAf8EBAMCBaAwCQYDVR0TBAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwNgYDVR0RBC8wLYIrdnN0cy12c3RzZ2hydC1naC12c28tb2F1dGgudm" \
              "lzdWFsc3R1ZGlvLmNvbTAfBgNVHSMEGDAWgBRZBaZCR9ghvStfcWaGwuHGjrfTgzAdBgNVHQ4EFgQUWQWmQkfYIb0rX3FmhsLhxo6304MwDQYJKoZIhvcNAQELBQADggEBA" \
              "GNdfALe6mdxQ67QL8GlW4dfFwvCX87JOeZThZ9uCj1+x1xUnywoR4o5q2DVI/JCvBRPn0BUb3dEVWLECXDHGjblesWZGMdSGYhMzWRQjVNmCYBC1ZM5QvonWCBcGkd72mZx" \
              "0eFHnJCAP/TqEEpRvMHR+OOtSiZWV9zZpF1tf06AjKwT64F9V8PCmSIqPJXcTQXKKfkHZmGUk9AYF875+/FfzF89tCnT53UEh5BldFz0SAls+NhexbW/oOokBNCVqe+T2xX" \
              "izktbFnFAFaomvwjVSvIeu3i/0Ygywl+3s5izMEsZ1T1ydIytv4FZf2JCHgRpmGPWJ5A7TpxuHSiE8Do="
            ],
            x5t: "eBZ_cn3sXYAd0ch4THBKHIgOwOE"
          },
          {
            n: "wgCsNL8S6evSH_AHBsps2ccIHSwLpuEUGS9GYenGmGkSKyWefKsZheKl_84voiUgduuKcKA2aWQezp9338LjtlBmTHjopzAeU-Q3_IvqNf7BfrEAzEyp-ymdhNzPTE7S" \
               "nmr5o_9AeiP1ZDBo35FaULgVUECJ3AzAM36zkURax3VNZRRZx1gb8lPUs9M5Yw6aZpHSOd6q_QzE8CP1OhGrAdoBzZ6ZCElon0kI-IuRLCwKptS7Yroi5-RtEKD2W458" \
               "axNAQ36Yw93N8kInUC1QZDPrKd4QfYiG68ywjBoxp_bjNg5kh4LJmq1mwyGdNQV6F1Ew_jYlmou2Y8wvHQRJPQ",
            kty: "RSA",
            kid: "52F197C481DE70112C441B4A9B37B53C7FCF0DB5",
            alg: "RS256",
            e: "AQAB",
            use: "sig",
            x5c: [
              "MIIDrDCCApSgAwIBAgIQLQnoXJ3HT6uPYvEofvOZ6zANBgkqhkiG9w0BAQsFADA2MTQwMgYDVQQDEyt2c3RzLXZzdHNnaHJ0LWdoLXZzby1vYXV0aC52aXN1YWxzdHVka" \
              "W8uY29tMB4XDTIxMTIwNjE5MDUyMloXDTIzMTIwNjE5MTUyMlowNjE0MDIGA1UEAxMrdnN0cy12c3RzZ2hydC1naC12c28tb2F1dGgudmlzdWFsc3R1ZGlvLmNvbTCCAS" \
              "IwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMIArDS/Eunr0h/wBwbKbNnHCB0sC6bhFBkvRmHpxphpEislnnyrGYXipf/OL6IlIHbrinCgNmlkHs6fd9/C47ZQZkx" \
              "46KcwHlPkN/yL6jX+wX6xAMxMqfspnYTcz0xO0p5q+aP/QHoj9WQwaN+RWlC4FVBAidwMwDN+s5FEWsd1TWUUWcdYG/JT1LPTOWMOmmaR0jneqv0MxPAj9ToRqwHaAc2e" \
              "mQhJaJ9JCPiLkSwsCqbUu2K6IufkbRCg9luOfGsTQEN+mMPdzfJCJ1AtUGQz6yneEH2IhuvMsIwaMaf24zYOZIeCyZqtZsMhnTUFehdRMP42JZqLtmPMLx0EST0CAwEAA" \
              "aOBtTCBsjAOBgNVHQ8BAf8EBAMCBaAwCQYDVR0TBAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwNgYDVR0RBC8wLYIrdnN0cy12c3RzZ2hydC1naC12c2" \
              "8tb2F1dGgudmlzdWFsc3R1ZGlvLmNvbTAfBgNVHSMEGDAWgBTTNQQWmG4PZZsdfMeamCH1YcyDZTAdBgNVHQ4EFgQU0zUEFphuD2WbHXzHmpgh9WHMg2UwDQYJKoZIhvc" \
              "NAQELBQADggEBAK/d+HzBSRac7p6CTEolRXcBrBmmeJUDbBy20/XA6/lmKq73dgc/za5VA6Kpfd6EFmG119tl2rVGBMkQwRx8Ksr62JxmCw3DaEhE8ZjRARhzgSiljqXH" \
              "lk8TbNnKswHxWmi4MD2/8QhHJwFj3X35RrdMM4R0dN/ojLlWsY9jXMOAvcSBQPBqttn/BjNzvn93GDrVafyX9CPl8wH40MuWS/gZtXeYIQg5geQkHCyP96M5Sy8ZABOo9" \
              "MSIfPRw1F7dqzVuvliul9ZZGV2LsxmZCBtbsCkBau0amerigZjud8e9SNp0gaJ6wGhLbstCZIdaAzS5mSHVDceQzLrX2oe1h4k="
            ],
            x5t: "UvGXxIHecBEsRBtKmze1PH_PDbU"
          }
        ]
      }.to_json,
      headers: {
        "content-type" => "application/json; charset=utf-8"
      }
    )

    fill_in "Comment", with: "A nice long comment"
    click_on "Refresh"

    page.assert_text "Action ran successfully!"
    page.assert_text provider.to_global_id.uri.to_s

    provider.reload

    audit = provider.audits.sole

    page.assert_text audit.id
    assert_equal "OIDC::Provider", audit.auditable_type
    assert_equal "Refresh OIDC Provider", audit.action
    assert_equal(
      "https://token.actions.githubusercontent.com/.well-known/jwks",
      audit.audited_changes.dig("records", "gid://gemcutter/OIDC::Provider/#{provider.id}", "changes", "configuration", 1, "jwks_uri")
    )
    assert_equal(
      "78167F727DEC5D801DD1C8784C704A1C880EC0E1",
      audit.audited_changes.dig("records", "gid://gemcutter/OIDC::Provider/#{provider.id}", "changes", "jwks", 1, "keys", 0, "kid")
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end
end
