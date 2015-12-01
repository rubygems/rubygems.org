class UserSerializer < ApplicationSerializer
  attributes :id, :email, :handle

  def email
    object.reload

    if object.hide_email == true
      return nil
    else
      return object.email
    end
  end

  def to_xml(options = {})
    super(options.merge(root: 'user'))
  end
end
