require 'spec_helper'
require 'singleton'

describe Dry::Config::Base do

  class AcmeConfig < Dry::Config::Base
    include Singleton
  end

  before do
    acmeConfig = AcmeConfig.instance
  end

  it '#set_option' do
    acmeConfig.clear
    acmeConfig.set_option('aws:elasticbeanstalk:application:environment', 'RACK_ENV', 'staging')
    expect(acmeConfig.options[:'aws:elasticbeanstalk:application:environment'][:'RACK_ENV']).to eq 'staging'
  end

  it '#find_option_setting_value' do
    acmeConfig.clear
    acmeConfig.set_option(:'aws:elasticbeanstalk:application:environment', 'RACK_ENV', 'staging')
    expect(acmeConfig.find_option_setting_value('RACK_ENV')).to eql 'staging'
  end
  it '#find_option_setting' do
    acmeConfig.clear
    acmeConfig.set_option(:'aws:elasticbeanstalk:application:environment', 'RACK_ENV', 'staging')
    expect(acmeConfig.find_option_setting('RACK_ENV')).to eql ({:namespace => 'aws:elasticbeanstalk:application:environment', :option_name => 'RACK_ENV', :value => 'staging'})
  end

  it '#set_option should allow options to be overridden' do
    acmeConfig.clear
    acmeConfig.set_option(:'aws:elasticbeanstalk:application:environment', 'RACK_ENV', 'staging')
    assert_option 'RACK_ENV', 'staging'
    acmeConfig.set_option(:'aws:elasticbeanstalk:application:environment', 'RACK_ENV', 'foo')
    assert_option 'RACK_ENV', 'foo'
  end

  it 'should read file with nil environment' do
    acmeConfig.clear
    sleep 1
    #expect(acmeConfig.strategy).to be_nil

    acmeConfig.load!(nil, config_file_path)
    assert_common_top_level_settings()
    assert_option 'InstanceType', 'foo'
    #expect(acmeConfig.strategy).to be_nil
    expect(acmeConfig.environment).to be_nil
  end

  it 'should read file and override with development environment' do
    acmeConfig.clear
    acmeConfig.load!(:development, config_file_path)
    assert_option 'InstanceType', 't1.micro'
    expect(acmeConfig.strategy).to eql 'inplace-update'
    expect(acmeConfig.environment).to eql 'development'
  end

  it 'should read file and override with production environment' do
    acmeConfig.clear
    acmeConfig.load!(:production, config_file_path)
    assert_option 'InstanceType', 't1.small'
    expect(acmeConfig.environment).to eql 'production'
  end

  private
  def assert_option(name, value)
    expect(acmeConfig.find_option_setting_value(name)).to eql value
  end

  def assert_common_top_level_settings
    expect(acmeConfig.app).to eql 'acme'
    expect(acmeConfig.region).to eql 'us-east-1'
    expect(acmeConfig.secrets_dir).to eql '~/.aws'
    expect(acmeConfig.strategy).to eql :blue_green
    expect(acmeConfig.solution_stack_name).to eql '64bit Amazon Linux running Ruby 1.9.3'
    expect(acmeConfig.disallow_environments).to eql %w(cucumber test)

    expect(acmeConfig.package[:dir]).to eql 'pkg'
    expect(acmeConfig.package[:verbose]).to be_true
    expect(acmeConfig.package[:includes]).to eql %w(**/* .ebextensions/**/*)
    expect(acmeConfig.package[:exclude_files]).to eql %w(resetdb.sh rspec.xml README* db/*.sqlite3)
    expect(acmeConfig.package[:exclude_dirs]).to eql %w(pkg tmp log test-reports solr features)

    # assert set_option new
    acmeConfig.set_option(:'aws:elasticbeanstalk:application:environment', 'RACK_ENV', 'staging')
    assert_option 'RACK_ENV', 'staging'

    # assert set_option overwrite
    acmeConfig.set_option(:'aws:elasticbeanstalk:application:environment', 'RAILS_ENV', 'staging')
    assert_option 'RAILS_ENV', 'staging'

    assert_option 'EC2KeyName', 'eb-ssh'

    assert_option 'SecurityGroups', 'acme-production-control'
    assert_option 'MinSize', '1'
    assert_option 'MaxSize', '5'
    assert_option 'SSLCertificateId', 'arn:aws:iam::XXXXXXX:server-certificate/acme'
    assert_option 'LoadBalancerHTTPSPort', '443'
    assert_option 'Stickiness Policy', 'true'
    assert_option 'Notification Endpoint', 'alerts@acme.com'
    assert_option 'Application Healthcheck URL', '/healthcheck'
  end

  def config_file_path
    File.expand_path('../acme.yml', __FILE__)
  end
end