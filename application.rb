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
    Dump.reverse_order(:created_at).all.map {|d|
      %[<a href="/dumps/#{d.id}/body">Fixture for #{d.id}</a> created on #{d.created_at}]
    }.join("<br/>")
  end

  get %r{/dumps/(\d+)/body} do |id|
    (d = Dump[id] || halt).body
  end

  post '/dump' do
    id = Dump.create params
    uri("/dumps/#{id}/body")
  end
end
