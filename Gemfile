source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

gem 'puma'
gem 'rack'
gem 'rake'
gem 'sinatra'
gem 'sequel'
gem 'pg'

group :development, :test do
  gem 'rack-test'
  gem 'rspec'
end

group :staging, :production do
  gem 'honeybadger'
end
