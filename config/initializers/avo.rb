# For more information regarding these settings check out our docs https://docs.avohq.io
Avo.configure do |config|
  ## == Routing ==
  config.root_path = '/admin'

  # Where should the user be redirected when visting the `/avo` url
  config.home_path = "/admin/dashboards/dashy"

  ## == Licensing ==
  config.license = 'pro' # change this to 'pro' when you add the license key
  config.license_key = ENV['AVO_LICENSE_KEY']

  ## == Set the context ==
  config.set_context do
    # Return a context object that gets evaluated in Avo::ApplicationController
  end

  ## == Authentication ==
  config.current_user_method = :admin_user
  config.authenticate_with do
    config.authenticate_with do
      redirect_to '/' unless admin_user&.valid?
    end
  end
  config.sign_out_path_name = :admin_logout_path

  ## == Authorization ==
  config.authorization_methods = {
    index: 'avo_index?',
    show: 'avo_show?',
    edit: 'avo_edit?',
    new: 'avo_new?',
    update: 'avo_update?',
    create: 'avo_create?',
    destroy: 'avo_destroy?',
  }
  config.raise_error_on_missing_policy = true
  config.authorization_client = :pundit

  ## == Localization ==
  # config.locale = 'en-US'

  ## == Resource options ==
  # config.resource_controls_placement = :right
  # config.model_resource_mapping = {}
  # config.default_view_type = :table
  # config.per_page = 24
  # config.per_page_steps = [12, 24, 48, 72]
  # config.via_per_page = 8
  # config.id_links_to_resource = false
  # config.cache_resources_on_index_view = true
  ## permanent enable or disable cache_resource_filters, default value is false
  # config.cache_resource_filters = false
  ## provide a lambda to enable or disable cache_resource_filters per user/resource.
  # config.cache_resource_filters = ->(current_user:, resource:) { current_user.cache_resource_filters?}

  ## == Customization ==
  config.app_name = "RubyGems.org (#{Rails.env})"
  # config.timezone = 'UTC'
  # config.currency = 'USD'
  # config.hide_layout_when_printing = false
  # config.full_width_container = false
  # config.full_width_index_view = false
  # config.search_debounce = 300
  # config.view_component_path = "app/components"
  # config.display_license_request_timeout_error = true
  # config.disabled_features = []
  # config.resource_controls = :right
  # config.tabs_style = :tabs # can be :tabs or :pills
  # config.buttons_on_form_footers = true
  # config.field_wrapper_layout = true

  ## == Branding ==
  # config.branding = {
  #   colors: {
  #     background: "248 246 242",
  #     100 => "#CEE7F8",
  #     400 => "#399EE5",
  #     500 => "#0886DE",
  #     600 => "#066BB2",
  #   },
  #   chart_colors: ["#0B8AE2", "#34C683", "#2AB1EE", "#34C6A8"],
  #   logo: "/avo-assets/logo.png",
  #   logomark: "/avo-assets/logomark.png",
  #   placeholder: "/avo-assets/placeholder.svg",
  #   favicon: "/avo-assets/favicon.ico"
  # }

  ## == Breadcrumbs ==
  # config.display_breadcrumbs = true
  # config.set_initial_breadcrumbs do
  #   add_breadcrumb "Home", '/avo'
  # end

  ## == Menus ==
  config.main_menu = -> {
    section "Dashboards", icon: "dashboards" do
      all_dashboards
    end

    section "Resources", icon: "resources" do
      all_resources
    end

    section "Tools", icon: "tools" do
      all_tools
    end unless all_tools.empty?
  }

  config.profile_menu = ->() {
    link_to "Admin Profile",
      path: avo.resources_admin_github_user_path(current_user),
      icon: "user-circle"
  }
end

Rails.configuration.to_prepare do
  Avo::ApplicationController.include GitHubOAuthable
end
