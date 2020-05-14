require 'bundler'
ENV['RACK_ENV'] ||= 'development'
Bundler.require(:default, ENV['RACK_ENV'])

ENV['DATABASE_URL'] ||= "postgres://#{ENV['USER']}:@localhost/dump_#{ENV['RACK_ENV']}"
DB = Sequel.connect(ENV['DATABASE_URL'])
DB.extension(:connection_validator)
DB.pool.connection_validation_timeout = -1

class Dump < Sequel::Model
  def before_create
    self.created_at ||= Time.now.utc
  end
end

class Dumpster < Sinatra::Base
  get '/' do
    query = Dump.reverse_order(:created_at).select(:id, :created_at, :key).limit(params[:limit] || 200)
    "<p>What can I dump for you today?</p>" +
     "<div><a href='/stats'>Daily deadlock stats</a></div>" +
     query.all.map {|d|
      "<a href='/dumps/#{d.id}/body'>Fixture for #{d.key}</a> created on #{d.created_at}"
    }.join('<br/>')
  end

  get '/stats' do
    table = "<table><thead><th>Date</th><th>Count</th></thead><tbody>"
    table += stats_query.all.map do |row|
      "<tr><td>#{row[:date]}</td><td>#{row[:count]}</td></tr>"
    end.join("\n")
    table += "</tbody></table>"

    "<h1>Daily deadlock statistics</h1> #{table}"
  end

  get '/stats.json' do
    require 'json'
    content_type :json

    stats_query.all.map { |row| [row[:date], row[:count]] }.to_json
  end

  get %r{/dumps/(\d+)/body} do |id|
    (Dump[id] || raise(Sinatra::NotFound)).body
  end

  post '/dump' do
    d = Dump.create params
    uri("/dumps/#{d.id}/body")
  end

  private

  def stats_query
    Dump
      .select(
        Sequel.lit('COUNT(*)').as(:count),
        Sequel.lit("to_char(created_at, 'YYYY-MM-DD')").as(:date)
      )
      .where { id > 661035 } # random HTML before this
      .group(Sequel.lit("to_char(created_at, 'YYYY-MM-DD')"))
      .order(Sequel.lit("to_char(created_at, 'YYYY-MM-DD') DESC"))
  end
end
