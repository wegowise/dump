require 'json'
require 'bundler'
Bundler.require(:default, (ENV['RACK_ENV'] || :development).to_sym)

uri = URI.parse(ENV['REDISTOGO_URL'] || 'redis://127.0.0.1')
REDIS =  Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
ENV['REDIS_DUMP'] ||= 'dump'
ENV['REDIS_PAYLOAD'] ||= 'payload'
ENV['PRIMARY_KEYS'] ||= 'class username'

class Dump < Sinatra::Base
  helpers do
    def dump_id(id)
      ENV['REDIS_DUMP'] + ":#{id}"
    end

    def payload_id(id)
      ENV['REDIS_PAYLOAD'] + ":#{id}"
    end
  end

  get '/' do
    'What would you like to dump today?'
  end

  get '/dumps/:id' do |id|
    hash = JSON.parse REDIS[dump_id(id)] || halt("Not Found")
    hash.map {|k,v| "#{k}: #{v}" }.join("<br/>") +
      "<br/><a href='/dumps/#{id}/payload'>Payload</a>"
  end

  get '/dumps/:id/payload' do |id|
    REDIS[payload_id(id)] || halt("Not Found")
  end

  post '/dump' do
    id = ENV['PRIMARY_KEYS'].split(' ').map {|e| params[e] }.join('-')
    id << "-#{Time.now.to_i}"
    REDIS[payload_id(id)] = params.delete('payload')
    REDIS[dump_id(id)] = JSON.generate(params)
    uri("/dumps/#{id}")
  end
end
