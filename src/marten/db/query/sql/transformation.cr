require "./transformation/**"

module Marten
  module DB
    module Query
      module SQL
        module Transformation
          @@registry = {} of String => Base.class

          def self.allows?(field : Field::Base, lookup_name : String) : Bool
            klass = @@registry[lookup_name]?
            klass ? klass.new(field).allows? : false
          end

          def self.register(klass : Base.class) : Nil
            @@registry[klass.transformation_name] = klass
          end

          def self.registered?(lookup_name : String) : Bool
            @@registry.has_key?(lookup_name)
          end

          def self.registry
            @@registry
          end

          register Day
          register Hour
          register Minute
          register Month
          register Second
          register Year
        end
      end
    end
  end
end
