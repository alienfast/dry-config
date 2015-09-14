require 'dry/config/deep_symbolizable'
require 'yaml'

module Dry
  module Config
#
# Dry::Config::Base allows for default settings and mounting a specific environment with
# overriding hash values and merging of array values.
#
#   NOTE: Anything can be overridden and merged into top-level settings (hashes) including
#   anything that is an array value.  Array values are merged *not* replaced.  If you think
#   something is screwy, see the defaults in the #initialize as those add some default array values.
#   If this behavior of merging arrays or the defaults are somehow un-sensible, file an issue and we'll revisit it.
#
    class Base
      attr_reader :configuration
      attr_reader :environment
      attr_reader :filenames

      def initialize(options = {})
        @options = {
            interpolation: true,
            symbolize: true,
            default_configuration: {},
            potential_environments: [:development, :test, :staging, :production]
        }.merge options

        @default_configuration = @options[:default_configuration]

        # used for pruning initial base set.  See #load!
        @potential_environments = @options[:potential_environments]

        # setup a default configuration
        clear
      end

      # This is the main point of entry - we call #load! and provide
      # a name of the file to read as it's argument. We can also pass in some
      # options, but at the moment it's being used to allow per-environment
      # overrides in Rails
      def load!(environment, *filenames)

        # raise 'Unspecified environment' if environment.nil?
        raise 'Unspecified filename' if filenames.nil?

        # ensure symbol
        environment = environment.to_sym unless environment.nil?

        # save these in case we #reload
        @environment = environment
        @filenames = filenames

        filenames.each do |filename|
          # merge all top level settings with the defaults set in the #init
          deep_merge!(@configuration, resolve_config(environment, filename))
        end
      end

      def resolve_config(environment, filename)

        config = load_yaml_file(filename)

        should_overlay_environment = environment && config[environment]

        # Prune all known environments so that we end up with the top-level configuration.
        @potential_environments.each do |env|
          config.delete(env)
        end

        # overlay the specific environment if provided
        if should_overlay_environment
          # re-read the file
          environment_settings = load_yaml_file(filename)

          # snag the requested environment
          environment_settings = environment_settings[environment.to_sym]

          # finally overlay what was provided the settings from the specific environment
          deep_merge!(config, environment_settings)
        end

        config
      end

      def load_yaml_file(filename)

        # without interpolation
        # config = Psych.load_file(filename)

        # get file contents as string
        file = File.open(filename, 'r:bom|utf-8')
        contents = file.read

        if @options[:interpolation]
          # interpolate/substitute/expand ENV variables with the string contents before parsing
          # bash - $VAR
          contents = contents.gsub(/\$(\w+)/) { ENV[$1] }
          # bash - ${VAR}
          contents = contents.gsub(/\${(\w+)}/) { ENV[$1] }
          # bash - ~ is ENV['HOME']
          contents = contents.gsub(/(~)/) { ENV['HOME'] }
          # ruby - #{VAR}
          contents = contents.gsub(/\#{(\w+)}/) { ENV[$1] }
        end
        # now parse
        config = Psych.load(contents, filename)

        raise "Failed to load #{filename}" if config.nil?
        config = config.deep_symbolize if @options[:symbolize]
        config
      end

      def write_yaml_file(filename)
        File.open(filename, 'w') do |file|
          file.write(Psych.dump(@configuration))
        end
      end

      def reload!
        clear
        load! @environment, @filenames
      end

      def clear
        # clone a copy of the default
        @configuration = {}.merge @default_configuration
        @configuration.deep_symbolize if @options[:symbolize]
      end

      def method_missing(name, *args, &block)
        @configuration[name.to_sym] ||
            #fail(NoMethodError, "Unknown settings root \'#{name}\'", caller)
            nil
      end

      private

      def deep_merge!(target, overrides)

        raise 'target cannot be nil' if target.nil?
        raise 'overrides cannot be nil' if overrides.nil?

        merger = proc { |key, v1, v2|
          if (Hash === v1 && Hash === v2)
            v1.merge(v2, &merger)
          elsif (Array === v1 && Array === v2)
            v1.concat(v2)
          else
            v2
          end
        }
        target.merge! overrides, &merger
      end
    end
  end
end