require_relative "../../lib/confirmed_user_guard"

Clearance.configure do |config|
  config.allow_sign_up = ENV['DISABLE_SIGNUP'].to_s != 'true'
  config.mailer_sender = "RubyGems.org <no-reply@mailer.rubygems.org>"
  config.secure_cookie = true unless Rails.env.test? || Rails.env.development?
  config.password_strategy = Clearance::PasswordStrategies::BCrypt
  config.sign_in_guards = [ConfirmedUserGuard]
  config.rotate_csrf_on_sign_in = true
  config.cookie_expiration = ->(_cookies) { 2.weeks.from_now.utc }
  config.routes = false
  config.signed_cookie = :migrate
end

class Clearance::Session
  def current_user
    return nil if remember_token.blank?
    return @current_user if @current_user
    user = user_from_remember_token(remember_token)

    @current_user = user if user&.remember_me?
  end

  def sign_in(user)
    @current_user = user
    cookies[remember_token_cookie] = user && user.remember_me!
    status = run_sign_in_stack

    unless status.success?
      @current_user = nil
      cookies[remember_token_cookie] = nil
    end

    yield(status) if block_given?
  end
end
