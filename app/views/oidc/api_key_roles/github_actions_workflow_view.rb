# frozen_string_literal: true

class OIDC::ApiKeyRoles::GitHubActionsWorkflowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :api_key_role

  def initialize(api_key_role:)
    @api_key_role = api_key_role
    super()
  end

  def view_template
    self.title = t(".title")

    subject_sidebar

    return render_not_configured unless configured?

    render CardComponent.new do |c|
      c.head { c.title(t(".title"), icon: "settings") }

      div(data: { controller: "clipboard", clipboard_success_content_value: "✔" }) do
        div(class: "text-lg mb-4") { gem_link }
        p(class: "text-b2 mb-4") { t(".configured_for_html", link_html: gem_name) }
        p(class: "text-b2 mb-4") { t(".to_automate_html", link_html: gem_name) }
        p(class: "text-b2 mb-8") { t(".instructions_html") }

        code_block
      end
    end
  end

  private

  COPY_BUTTON = "shrink-0 p-1 rounded text-b4 cursor-pointer " \
                "text-neutral-700 dark:text-neutral-400 " \
                "hover:bg-neutral-100 hover:text-neutral-800 active:bg-neutral-200 " \
                "dark:hover:bg-neutral-800 dark:hover:text-white dark:active:bg-neutral-700 " \
                "transition duration-200 ease-in-out"

  def subject_sidebar
    content_for :subject do
      raw view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :profile })
    end
  end

  def code_block
    div(class: "rounded-lg border border-neutral-200 dark:border-neutral-800 overflow-hidden") do
      div(class: "flex items-center justify-between gap-2 px-4 py-2 " \
                 "border-b border-neutral-200 dark:border-neutral-800 " \
                 "bg-neutral-050 dark:bg-neutral-950") do
        code(class: "text-c4 font-mono text-neutral-800 dark:text-neutral-200") { ".github/workflows/push_gem.yml" }
        button(
          type: :button,
          class: COPY_BUTTON,
          title: t("copy_to_clipboard"),
          aria: { label: t("copy_to_clipboard") },
          data: { action: "click->clipboard#copy", clipboard_target: "button" }
        ) { icon_tag("content-copy", size: 5, class: "pointer-events-none") }
      end
      pre(class: "overflow-x-auto p-4 text-c4 bg-white dark:bg-black") do
        code(class: "font-mono", id: "workflow_yaml", data: { clipboard_target: "source" }) do
          plain workflow_yaml
        end
      end
    end
  end

  def render_not_configured
    render CardComponent.new do |c|
      c.head { c.title(t(".title"), icon: "settings") }

      p(class: "text-b2") { t(".not_github") } unless github?
      p(class: "text-b2") { t(".not_push") } unless push?
    end
  end

  def gem_link
    render link_to("#{gem_name} →", rubygem_path(gem_name), class: "text-orange-500 hover:underline")
  end

  def gem_name
    if single_gem_role?
      api_key_role.api_key_permissions.gems.first
    else
      "YOUR_GEM_NAME"
    end
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
            { uses: "actions/checkout@v4", with: { "persists-credentials": false } },
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

  def configured?
    github? && push?
  end

  def github?
    api_key_role.provider.github_actions?
  end

  def push?
    api_key_role.api_key_permissions.scopes.include?("push_rubygem")
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
