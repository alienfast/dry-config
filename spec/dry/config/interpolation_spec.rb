require 'spec_helper'
require 'singleton'

describe Dry::Config::Base do

  class ComposeConfig < Dry::Config::Base

  end

  subject(:config) { ComposeConfig.new }

  before(:each){FileUtils.rm_r tmp_dir}

  context 'no interpolation' do
    let(:config_file_name) { 'docker-compose-template-simple.yml' }

    it 'should read file and write file with all values intact' do
      config.clear
      config.load!(nil, config_file_name_path)

      expected_config = config.configuration
      tmp_file = tmp_file(config_file_name.gsub('.', '-out.'))
      config.write_yaml_file(tmp_file)

      config.clear
      config.load!(nil, tmp_file)
      actual_config = config.configuration

      expect(actual_config).to eq expected_config
    end
  end

  # context 'no interpolation' do
  #   let(:config_file_name) { 'docker-compose-template.yml' }
  #
  # end

  private

  def config_file_name_path
    File.expand_path("../#{config_file_name}", __FILE__)
  end
  
  def tmp_file(filename)
    file = File.expand_path(filename, tmp_dir)
    file
  end

  def tmp_dir
    dir = File.expand_path("../.././../../tmp/interpolation", __FILE__)
    FileUtils.mkdir_p(dir) unless File.exists? dir
    dir
  end
end