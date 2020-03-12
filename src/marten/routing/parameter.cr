module Marten
  module Routing
    module Parameter
      @@registry = {} of ::String => Base

      def self.register(id : ::String | Symbol, parameter_klass : Base.class)
        @@registry[id.to_s] = parameter_klass.new
      end

      def self.registry
        @@registry
      end

      register :string, String
    end
  end
end
