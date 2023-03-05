module Marten
  module DB
    class Index
      getter name
      getter fields

      def initialize(@name : String, @fields : Array(Field::Base))
      end

      # Returns a clone of the current index.
      def clone
        Index.new(name: name, fields: fields)
      end
    end
  end
end
