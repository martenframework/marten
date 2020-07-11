require "./predicate/**"

module Marten
  module DB
    module SQL
      module Predicate
        @@registry = {} of String => Base.class

        def self.register(predicate_klass : Base.class)
          @@registry[predicate_klass.predicate_name] = predicate_klass
        end

        def self.registry
          @@registry
        end

        register Exact
      end
    end
  end
end
