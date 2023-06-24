class ReserveNamespace < BaseAction
  self.name = "Reserve Namespace"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Reserve Namespace"

  field :name, name: "Name", as: :text, required: true
  field :version, name: "Version", as: :text, required: true, default: "0.0.0.reserved"

  class ActionHandler < ActionHandler
    def handle_standalone
      if (rubygem = Rubygem.find_by(name: fields["name"])) && rubygem.indexed_versions?
        raise "This gem has indexed versions. To reserve the namespace, first yank all indexed versions."
      end

      user = User.find_by!(email: "security@rubygems.org")
      gemcutter = Pusher.new(user, gem_body)
      raise("Failed to push gem: #{gemcutter.message}") unless gemcutter.process
      succeed("Namespace reserved: #{gemcutter.message}")
      gemcutter.version
    end

    private

    def gem_body
      io = StringIO.new
      package = Gem::Package.new(io, nil)
      package.spec = Gem::Specification.new do |s|
        s.name = fields["name"]
        s.version = fields["version"]
        s.authors = ["RubyGems.org"]
        s.summary = "This gem namespace is reserved by RubyGems.org"
      end

      # TODO: delete once https://github.com/rubygems/rubygems/pull/6769 is released
      source = package.gem
      def source.path
        "reserved.gem"
      end

      package.build
      io.tap(&:rewind)
    end
  end
end
