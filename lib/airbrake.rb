if ENV['AIRBRAKE_API_KEY']
  Airbrake.configure do |config|
    # the API key needs to be in an environment variable since this is a
    # public repo
    config.api_key = ENV['AIRBRAKE_API_KEY']
  end

  class Dumpster < Sinatra::Base
    if production?
      use Airbrake::Rack
      enable :raise_errors
    end
  end
end

