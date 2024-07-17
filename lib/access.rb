module Access
  AccessDeniedError = Class.new(StandardError)

  GUEST = 0
  MAINTAINER = 60
  OWNER = 70
end
