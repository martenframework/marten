module Marten
  module Template
    module Object
      # Allows to expose enum values in templates contexts.
      #
      # This class serves as a "wrapper" for a real enum value, containing both its "value" and "name". It enables
      # smooth manipulation of such enum values within a template runtime. Ordinary enum values cannot be used directly
      # in templates because Enum be added to union types, hence why this class is necessary.
      class Enum
        include Marten::Template::Object

        getter enum_class_name
        getter enum_value_names
        getter name
        getter value

        def initialize(@enum_class_name : String, @enum_value_names : Array(String), @name : String, @value : Int64)
        end

        def ==(other : self)
          super || (enum_class_name == other.enum_class_name && name == other.name && value == other.value)
        end

        def ==(other : ::Enum)
          super || (enum_class_name == other.class.name && name == other.to_s && value == other.to_i64)
        end

        # :nodoc:
        def resolve_template_attribute(key : String)
          case key
          when "#{name.underscore}?"
            true
          when "name"
            name
          when "value"
            value
          else
            enum_value_names.map { |v| "#{v.underscore}?" }.includes?(key) ? false : nil
          end
        end

        # :nodoc:
        def to_s(io)
          value.to_s(io)
        end
      end
    end
  end
end
