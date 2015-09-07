require 'rubygems'
require 'bundler/setup'

# our gem
require 'dry/config'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # config.include Dry::Config::Foo
end
