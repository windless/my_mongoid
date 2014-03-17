require "my_mongoid/version"

module MyMongoid
  module Document
    def self.included(base)
      base.extend(ClassMethods)
      base.field :_id
      base.alias_field :id, :_id

      MyMongoid.models << base
    end

    def initialize(attributes)
      raise ArgumentError unless attributes.is_a?(Hash)
      self.attributes = attributes
    end

    def attributes
      @attributes ||= {}
    end

    def read_attribute(name)
      @attributes[name]
    end

    def write_attribute(name, value)
      @attributes[name] = value
    end

    def new_record?
      true
    end

    def process_attributes(attributes)
      attributes.each do |key, value|
        raise UnknownAttributeError unless respond_to?(key)
        send("#{key}=", value)
      end 
    end

    alias_method :attributes=, :process_attributes

    module ClassMethods
      def is_mongoid_model?
        true
      end

      def field(name, options = nil)
        name = name.to_s
        define_field(name)
        alias_field options[:as], name if options && options[:as]
        fields[name] = Field.new(name, options)
      end

      def fields
        @fields ||= {}
      end

      def alias_field(new_field, origin_field)
        alias_method new_field, origin_field
        alias_method "#{new_field}=", "#{origin_field}="
      end

      private

      def field_defined?(field_name)
        self.fields.keys.include?(field_name)
      end

      def define_field(name)
        raise DuplicateFieldError if field_defined?(name)

        define_method(name) do
          attributes[name.to_s]
        end

        define_method("#{name}=") do |value|
          attributes[name] = value
        end
      end
    end
  end

  def self.models
    @models ||= []
  end

  class DuplicateFieldError < StandardError; end
  class UnknownAttributeError < StandardError; end

  class Field
    attr_accessor :name, :options

    def initialize(name, options)
      self.name = name
      self.options = options
    end
  end
end
