require 'ostruct'

module Config
  class Options < OpenStruct
    include Enumerable

    def keys
      marshal_dump.keys
    end

    def empty?
      marshal_dump.empty?
    end

    def add_source!(source)
      # handle yaml file paths
      source = (Sources::YAMLSource.new(source)) if source.is_a?(String)

      @config_sources ||= []
      @config_sources << source
    end

    def prepend_source!(source)
      source = (Sources::YAMLSource.new(source)) if source.is_a?(String)

      @config_sources ||= []
      @config_sources.unshift(source)
    end

    def reload_env!
      return self if ENV.nil? || ENV.empty?
      conf = Hash.new
      ENV.each do |key, value|
        next unless key.to_s.index(Config.env_prefix || Config.const_name) == 0
        hash = Config.env_parse_values ? __value(value) : value
        key.to_s.split(Config.env_separator).reverse[0...-1].each do |element|
          element = case Config.env_converter
          when :downcase then element.downcase
          when nil then element
          else raise "Invalid env converter: #{Config.env_converter}"
          end

          hash = {element => hash}
        end
        DeepMerge.deep_merge!(hash, conf, :preserve_unmergeables => false)
      end

      merge!(conf)
    end

    alias :load_env! :reload_env!

    # look through all our sources and rebuild the configuration
    def reload!
      conf = {}
      @config_sources.each do |source|
        source_conf = source.load

        if conf.empty?
          conf = source_conf
        else
          # see Options Details in lib/rails_config/vendor/deep_merge.rb
          DeepMerge.deep_merge!(source_conf,
                                conf,
                                preserve_unmergeables: false,
                                knockout_prefix: Config.knockout_prefix)
        end
      end

      # swap out the contents of the OStruct with a hash (need to recursively convert)
      marshal_load(__convert(conf).marshal_dump)

      reload_env! if Config.use_env

      self
    end

    alias :load! :reload!

    def reload_from_files(*files)
      Config.load_and_set_settings(files)
      reload!
    end

    def to_hash
      result = {}
      marshal_dump.each do |k, v|
        if v.instance_of? Config::Options
          result[k] = v.to_hash
        elsif v.instance_of? Array
          result[k] = descend_array(v)
        else
          result[k] = v
        end
      end
      result
    end

    def each(*args, &block)
      marshal_dump.each(*args, &block)
    end

    def to_json(*args)
      require "json" unless defined?(JSON)
      to_hash.to_json(*args)
    end

    def merge!(hash)
      current = to_hash
      DeepMerge.deep_merge!(hash.dup, current)
      marshal_load(__convert(current).marshal_dump)
      self
    end

    # Some keywords that don't play nicely with OpenStruct
    SETTINGS_RESERVED_NAMES = %w{select collect}

    # An alternative mechanism for property access.
    # This let's you do foo['bar'] along with foo.bar.
    def [](param)
      return super if SETTINGS_RESERVED_NAMES.include?(param)
      send("#{param}")
    end

    def []=(param, value)
      send("#{param}=", value)
    end

    SETTINGS_RESERVED_NAMES.each do |name|
      define_method name do
        self[name]
      end
    end

    protected

    def descend_array(array)
      array.length.times do |i|
        value = array[i]
        if value.instance_of? Config::Options
          array[i] = value.to_hash
        elsif value.instance_of? Array
          array[i] = descend_array(value)
        end
      end
      array
    end

    # Recursively converts Hashes to Options (including Hashes inside Arrays)
    def __convert(h) #:nodoc:
      s = self.class.new

      h.each do |k, v|
        k = k.to_s if !k.respond_to?(:to_sym) && k.respond_to?(:to_s)
        s.new_ostruct_member(k)

        if v.is_a?(Hash)
          v = v["type"] == "hash" ? v["contents"] : __convert(v)
        elsif v.is_a?(Array)
          v = v.collect { |e| e.instance_of?(Hash) ? __convert(e) : e }
        end

        s.send("#{k}=".to_sym, v)
      end
      s
    end

    # Return an integer if it looks like one
    def __value(v)
      Integer(v) rescue v
    end
  end
end
