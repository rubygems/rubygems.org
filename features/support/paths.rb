module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /the homepage/
      root_path
    when /the home page/
      root_path
    when /the sign up page/
      new_user_path
    when /the sign in page/
      new_session_path
    when /the password reset request page/
      new_password_path
    when /the dashboard/
      dashboard_path
    when /my edit profile page/
      edit_profile_path
    when /"([^\"]+)" profile page/
      profile_path(User.find_by_email!($1))

    # Add more mappings here.
    when /the sign up page/i
          sign_up_path
        when /the sign in page/i
          sign_in_path
        when /the password reset request page/i
          new_password_path
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
