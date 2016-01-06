if ENV['HONEYBADGER_API_KEY']
  class Dumpster < Sinatra::Base
    if production?
      honeybadger_config = Honeybadger::Config.new(env: ENV['RACK_ENV'])
      Honeybadger.start(honeybadger_config)
      use Honeybadger::Rack::ErrorNotifier, honeybadger_config
    end
  end
end
