require 'bundler'
Bundler.require(:default, (ENV['RACK_ENV'] || :development).to_sym)

ENV['DATABASE_URL'] ||= "postgres://#{ENV['USER']}:@localhost/dump_development"
DB = Sequel.connect(ENV['DATABASE_URL'])

class Dump < Sequel::Model
  def before_create
    self.created_at ||= Time.now.utc
  end
end

class Dumpster < Sinatra::Base
  helpers Sinatra::Toadhopper
  set :toadhopper, api_key: ENV['HOPTOAD_API_KEY'], notify_host: ENV['HOPTOAD_HOST']

  get '/' do
    "<h1>What can I dump for you today?</h1>" +
    Dump.reverse_order(:created_at).all.map {|d|
      %[<a href="/dumps/#{d.id}/body">Fixture for #{d.key}</a> created on #{d.created_at}]
    }.join('<br/>')
  end

  get %r{/dumps/(\d+)/body} do |id|
    (Dump[id] || raise(Sinatra::NotFound)).body
  end

  post '/dump' do
    d = Dump.create params
    uri("/dumps/#{d.id}/body")
  end

  error(400..510) { post_error_to_hoptoad!; $!.message } if production?
end
