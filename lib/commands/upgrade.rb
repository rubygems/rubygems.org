class Gem::StreamUI
  def ask_for_password(message)
    system "stty -echo"
    password = ask(message)
    system "stty echo"
    password
  end
end

class Gem::Commands::UpgradeCommand < Gem::Command
  def description
    'Upgrade your gem source to Gemcutter'
  end

  def ask_for_password(message)
    ui.ask_for_password(message)
  end

  def initialize
    super 'upgrade', description
  end

  def execute
    add_source
    sign_in
  end

  def add_source
    if Gem.sources.include?(URL)
      say "Gemcutter is already your primary gem source. Please use `gem downgrade` if you wish to no longer use Gemcutter."
    else
      say "Upgrading your primary gem source to gemcutter.org"
      Gem.sources.unshift URL
      Gem.configuration.write
    end
  end

  def sign_in
    say "Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up"

    user = ask("Email: ")
    password = ask_for_password("Password: ")
  end

end

Gem::CommandManager.instance.register_command :upgrade
