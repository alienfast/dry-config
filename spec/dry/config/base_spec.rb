require 'spec_helper'
require 'singleton'

describe Dry::Config::Base do

  class AcmeConfig < Dry::Config::Base
    include Singleton

    def seed_default_configuration
      # seed the sensible defaults here
      @configuration = {
          environment: nil,
          strategy: :blue_green,
          package: {
              verbose: false
          },
          options: {}
      }
    end
  end

  subject(:acmeConfig) { AcmeConfig.instance }

  it 'should work as a singleton' do
    expect(acmeConfig).to equal(AcmeConfig.instance)
  end

  it 'should not raise error when key is not found' do
    acmeConfig.clear
    expect(acmeConfig.app).to be_nil
  end

  it 'should provide seed configuration' do
    acmeConfig.clear
    assert_common_seed_settings
    expect(acmeConfig.options.length).to eql 0
  end

  it 'should read file with nil environment' do
    acmeConfig.clear
    acmeConfig.load!(nil, config_file_path)

    assert_common_seed_settings
    assert_common_top_level_settings

    assert_option :'aws:elasticbeanstalk:application:environment', :RAILS_ENV, 'foobar'
    assert_option :'aws:autoscaling:launchconfiguration', :InstanceType, 'foo'
  end

  it 'should read file and override with development environment' do
    acmeConfig.clear
    acmeConfig.load!(:development, config_file_path)

    # assert_common_seed_settings
    assert_common_top_level_settings

    assert_option :'aws:elasticbeanstalk:application:environment', :RAILS_ENV, 'development'
    assert_option :'aws:autoscaling:launchconfiguration', :InstanceType, 't1.micro'

    expect(acmeConfig.package[:verbose]).to eql true
    expect(acmeConfig.strategy).to eql 'inplace-update'
  end

  it 'should read file and override with production environment' do
    acmeConfig.clear
    acmeConfig.load!(:production, config_file_path)

    # assert_common_seed_settings
    assert_common_top_level_settings

    assert_option :'aws:elasticbeanstalk:application:environment', :RAILS_ENV, 'production'
    assert_option :'aws:autoscaling:launchconfiguration', :InstanceType, 't1.large'

    expect(acmeConfig.package[:verbose]).to eql false

    # seed values
    expect(acmeConfig.strategy).to eql :blue_green
    expect(acmeConfig.package[:verbose]).to eql false
  end

  private

  def assert_option(section, name, value)
    expect(acmeConfig.options[section][name]).to eql value
  end


  def assert_common_seed_settings
    expect(acmeConfig.strategy).to eql :blue_green
    expect(acmeConfig.environment).to be_nil
    expect(acmeConfig.package[:verbose]).to eql false
    expect(acmeConfig.options).not_to be_nil
  end

  def assert_common_top_level_settings
    expect(acmeConfig.app).to eql 'acme'
    expect(acmeConfig.title).to eql 'Acme Holdings, LLC'
  end

  def config_file_path
    File.expand_path('../acme.yml', __FILE__)
  end
end