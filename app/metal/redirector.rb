class Redirector < Sinatra::Default
  %w[book chapter export read shelf syndicate].each do |resource|
    get "/#{resource}*" do
      status 301
      response['Location'] = "http://docs.rubygems.org#{request.path}"
      halt
    end
  end
end
