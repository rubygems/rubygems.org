class UsersController < Clearance::UsersController
  ssl_required
  
  private 
    def user_from_params
      user_params = params[:user] || Hash.new
      email       = user_params.delete(:email)
      password    = user_params.delete(:password)
      handle      = user_params.delete(:handle)
    
      Clearance.configuration.user_model.new(user_params).tap do |user|
        user.handle   = handle
        user.email    = email
        user.password = password
      end
    end
end
