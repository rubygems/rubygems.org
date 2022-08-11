class ResetJoshmnKey < ActiveRecord::Migration[7.0]
  def change
    user = User.find_by_slug("joshmn")
    return unless user 
    
    user.disable_mfa!
  end
end
