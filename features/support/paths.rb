module NavigationHelpers
  def path_to(page_name)
    case page_name
    when /the homepage/
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
     profile_path(User.first)
    else
      raise "Can't find mapping from \"#{page_name}\" to a path."
    end
  end
end

World(NavigationHelpers)
