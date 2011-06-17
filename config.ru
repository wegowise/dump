require './application'

if ENV['DUMPSTER_USERNAME'] && ENV['DUMPSTER_PASSWORD']
  use Rack::Auth::Basic, "The Dumpster is hungry" do |username, password|
    [username, password] == [ENV['DUMPSTER_USERNAME'], ENV['DUMPSTER_PASSWORD']]
  end
end

run Dumpster
