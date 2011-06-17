require 'bundler'
Bundler.require(:default, (ENV['RACK_ENV'] || :development).to_sym)

if ['development', nil].include? ENV['RACK_ENV']
 ENV['DATABASE_URL'] ||= "postgres://#{ENV['USER']}:@localhost/dump_development"
end
DB = Sequel.connect(ENV['DATABASE_URL'])

class Dump < Sequel::Model
  def before_create
    self.created_at ||= Time.now.utc
  end
end

class Dumpster < Sinatra::Base
  get '/' do
    "<h1>What can I dump for you today?</h1>" +
    Dump.reverse_order(:created_at).all.map {|d|
      %[<a href="/dumps/#{d.id}/body">Fixture for #{d.key}</a> created on #{d.created_at}]
    }.join('<br/>')
  end

  get %r{/dumps/(\d+)/body} do |id|
    (Dump[id] || halt).body
  end

  post '/dump' do
    d = Dump.create params
    uri("/dumps/#{d.id}/body")
  end
end
