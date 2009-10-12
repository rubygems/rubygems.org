# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{clearance}
  s.version = "0.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Croak", "Mike Burns", "Jason Morrison", "Joe Ferris", "Eugene Bolshakov", "Nick Quaranto", "Josh Nichols", "Mike Breen", "Marcel G\303\266rner", "Bence Nagy", "Ben Mabey", "Eloy Duran", "Tim Pope", "Mihai Anca", "Mark Cornick", "Shay Arnett"]
  s.date = %q{2009-09-01}
  s.description = %q{Rails authentication with email & password.}
  s.email = %q{support@thoughtbot.com}
  s.files = ["CHANGELOG.textile", "LICENSE", "Rakefile", "README.textile", "TODO.textile", "app/controllers/clearance/confirmations_controller.rb", "app/controllers/clearance/passwords_controller.rb", "app/controllers/clearance/sessions_controller.rb", "app/controllers/clearance/users_controller.rb", "app/models/clearance_mailer.rb", "app/views/clearance_mailer/change_password.html.erb", "app/views/clearance_mailer/confirmation.html.erb", "app/views/passwords/edit.html.erb", "app/views/passwords/new.html.erb", "app/views/sessions/new.html.erb", "app/views/users/_form.html.erb", "app/views/users/new.html.erb", "config/clearance_routes.rb", "generators/clearance/clearance_generator.rb", "generators/clearance/lib/insert_commands.rb", "generators/clearance/lib/rake_commands.rb", "generators/clearance/templates/factories.rb", "generators/clearance/templates/migrations/create_users.rb", "generators/clearance/templates/migrations/update_users.rb", "generators/clearance/templates/README", "generators/clearance/templates/user.rb", "generators/clearance/USAGE", "generators/clearance_features/clearance_features_generator.rb", "generators/clearance_features/templates/features/password_reset.feature", "generators/clearance_features/templates/features/sign_in.feature", "generators/clearance_features/templates/features/sign_out.feature", "generators/clearance_features/templates/features/sign_up.feature", "generators/clearance_features/templates/features/step_definitions/clearance_steps.rb", "generators/clearance_features/templates/features/step_definitions/factory_girl_steps.rb", "generators/clearance_features/templates/features/support/paths.rb", "generators/clearance_features/USAGE", "generators/clearance_views/clearance_views_generator.rb", "generators/clearance_views/templates/formtastic/passwords/edit.html.erb", "generators/clearance_views/templates/formtastic/passwords/new.html.erb", "generators/clearance_views/templates/formtastic/sessions/new.html.erb", "generators/clearance_views/templates/formtastic/users/_inputs.html.erb", "generators/clearance_views/templates/formtastic/users/new.html.erb", "generators/clearance_views/USAGE", "lib/clearance/authentication.rb", "lib/clearance/extensions/errors.rb", "lib/clearance/extensions/rescue.rb", "lib/clearance/extensions/routes.rb", "lib/clearance/user.rb", "lib/clearance.rb", "shoulda_macros/clearance.rb", "rails/init.rb"]
  s.homepage = %q{http://github.com/thoughtbot/clearance}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Rails authentication with email & password.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
