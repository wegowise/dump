ENV['RACK_ENV'] = 'test'

require File.expand_path('../application', __dir__)
require 'rspec'
require 'rack/test'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.around(:each) do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end
