require "puma/plugin"

Puma::Plugin.create do
  def start(launcher)
    in_background do
      warn "Starting TailwindCSS watcher..."
      system(
        File.expand_path("../../../bin/rails", __dir__), "--trace", "tailwindcss:watch", "RAILS_GROUPS=assets",
        %i[out err] => File.expand_path("../../../log/tailwind.log", __dir__),
        exception: true
      )
    rescue StandardError => e
      warn e.full_message(highlight: true)
      launcher.restart
    end
  end
end
