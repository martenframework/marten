module Marten
  module DB
    class QuerySet
      def initialize(@model_klass : Model.class)
        @query = SQL::Query.new(@model_klass)
      end

      def count
        @query.count
      end
    end
  end
end
