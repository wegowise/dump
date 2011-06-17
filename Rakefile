desc "Migrate database"
task :migrate => :environment do
  sh("bundle exec sequel -m migrations $DATABASE_URL")
end

task :environment do
  require './application'
end
