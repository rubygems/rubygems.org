# frozen_string_literal: true

class OIDC::ApiKeyRoles::GitHubActionsWorkflowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :api_key_role

  def initialize(api_key_role:)
    @api_key_role = api_key_role
    super()
  end

  def view_template
    self.title = t(".title")

    return if not_configured

    div(class: "t-body") do
      p do
        t(".configured_for_html", link_html:
          single_gem_role? ? helpers.link_to(gem_name, rubygem_path(gem_name)) : t(".a_gem"))
      end

      p do
        t(".to_automate_html", link_html:
         single_gem_role? ? helpers.link_to(gem_name, rubygem_path(gem_name)) : t(".a_gem"))
      end

      p { t(".instructions_html") }

      header(class: "gem__code__header") do
        h3(class: "t-list__heading l-mb-0") { code { ".github/workflows/push_gem.yml" } }
        button(class: "gem__code__icon", data: { "clipboard-target": "#workflow_yaml" }) { "=" }
        span(class: "gem__code__tooltip--copy") { t("copy_to_clipboard") }
        span(class: "gem__code__tooltip--copied") { t("copied") }
      end
      pre(class: "gem__code multiline") do
        code(class: "multiline", id: "workflow_yaml") do
          plain workflow_yaml
        end
      end
    end
  end

  private

  def gem_name
    single_gem_role? ? api_key_role.api_key_permissions.gems.first : "YOUR_GEM_NAME"
  end

  def workflow_yaml
    YAML.safe_dump({
      on: { push: { tags: ["v*"] } },
      name: "Push Gem",
      jobs: {
        push: {
          "runs-on": "ubuntu-latest",
          permissions: {
            contents: "write",
            "id-token": "write"
          },
          steps: [
            { uses: "rubygems/configure-rubygems-credentials@main",
              with: { "role-to-assume": api_key_role.token, audience: configured_audience, "gem-server": gem_server_url }.compact },
            { uses: "actions/checkout@v4" },
            { name: "Set remote URL", run: set_remote_url_run },
            { name: "Set up Ruby", uses: "ruby/setup-ruby@v1", with: { "bundler-cache": true, "ruby-version": "ruby" } },
            { name: "Release", run: "bundle exec rake release" },
            { name: "Wait for release to propagate", run: await_run }
          ]
        }
      }
    }.deep_stringify_keys)
  end

  def set_remote_url_run
    <<~BASH
      # Attribute commits to the last committer on HEAD
      git config --global user.email "$(git log -1 --pretty=format:'%ae')"
      git config --global user.name "$(git log -1 --pretty=format:'%an')"
      git remote set-url origin "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/$GITHUB_REPOSITORY"
    BASH
  end

  def await_run
    <<~BASH
      gem install rubygems-await
      gem_tuple="$(ruby -rbundler/setup -rbundler -e '
          spec = Bundler.definition.specs.find {|s| s.name == ARGV[0] }
          raise "No spec for \#{ARGV[0]}" unless spec
          print [spec.name, spec.version, spec.platform].join(":")
        ' #{gem_name.dump})"
      gem await #{"--source #{gem_server_url.dump} " if gem_server_url}"${gem_tuple}"
    BASH
  end

  def not_configured
    is_github = api_key_role.provider.github_actions?
    is_push = api_key_role.api_key_permissions.scopes.include?("push_rubygem")
    return if is_github && is_push
    div(class: "t-body") do
      p { t(".not_github") } unless is_github
      p { t(".not_push") } unless is_push
    end
    true
  end

  def configured_audience
    auds = api_key_role.access_policy.statements.flat_map do |s|
      next unless s.effect == "allow"

      s.conditions.flat_map do |c|
        c.value if c.claim == "aud"
      end
    end
    auds.compact!
    auds.uniq!

    return unless auds.size == 1
    aud = auds.first
    aud if aud != "rubygems.org" # default in action
  end

  def gem_server_url
    host = Gemcutter::HOST
    return if host == "rubygems.org" # default in action
    "https://#{host}"
  end

  def single_gem_role?
    api_key_role.api_key_permissions.gems&.size == 1
  end
end
