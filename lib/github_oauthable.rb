module GitHubOAuthable
  extend ActiveSupport::Concern

  INFO_QUERY = <<~GRAPHQL.freeze
    query($organization_name:String!) {
      viewer {
        name
        login
        email
        avatarUrl
        id
        organization(login: $organization_name) {
          login
          name
          viewerIsAMember
          teams(first: 20, role: MEMBER) {
            edges {
              node {
                name
                slug
              }
            }
          }
        }
      }
    }
  GRAPHQL

  included do
    before_action :set_error_context_user if respond_to?(:before_action)

    def admin_user
      request.fetch_header(admin_user_request_header) do
        find_admin_user
      end
    end

    def find_admin_user
      return unless (cookie = cookies.encrypted[admin_cookie_name].presence)
      Admin::GitHubUser.admins.find_by(id: cookie)
    end

    def admin_logout
      cookies.delete(admin_cookie_name)
      redirect_to root_path
    end

    def admin_github_login!(token:)
      info_data = fetch_admin_user_info(token)
      user = Admin::GitHubUser.find_or_initialize_by(github_id: info_data.dig(:viewer, :id))
      user.is_admin = true # will be set to false if the is_admin validation fails
      user.oauth_token = token
      user.info_data = info_data
      if user.invalid? && user.errors.group_by_attribute.keys == %i[is_admin]
        is_admin_error = ActiveModel::ValidationError.new(user)
        user.is_admin = false
      end

      # Avoid saving details for random people who go through the auth flow.
      user.save! if user.is_admin || user.persisted?

      if user.is_admin
        request.flash.now[:warning] = "Logged in as a admin via GitHub as #{user.name}"
        cookies.encrypted[admin_cookie_name] = {
          value: user.id,
          expires: 1.hour,
          same_site: :lax
        }
      else
        request.flash[:error] = "#{user.name} on GitHub is not a valid admin"
        raise is_admin_error
      end
    end

    def admin_cookie_name
      "rubygems_admin_oauth_github_user"
    end

    def admin_user_request_header
      "gemcutter.rubygems_admin_oauth_github_user"
    end

    def fetch_admin_user_info(oauth_token)
      github_client = Octokit::Client.new(access_token: oauth_token)
      graphql = github_client.post(
        "/graphql",
        { query: INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json
      )
      if (errors = graphql.errors.presence)
        Rails.logger.warn("GitHub graphql errors: #{errors}")
      end
      graphql.data.to_h.deep_symbolize_keys
    end

    def set_error_context_user
      return unless admin_user

      Rails.error.set_context(
        user_id: admin_user.github_id
      )
    end
  end
end
