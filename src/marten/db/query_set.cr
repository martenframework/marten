module Marten
  module DB
    class QuerySet(Model)
      include Enumerable(Model)

      @result_cache : Array(Model)?

      def initialize
        @query = SQL::Query(Model).new
      end

      def each
        fetch if @result_cache.nil?
        @result_cache.not_nil!.each do |r|
          yield r
        end
      end

      def first
        @result_cache.nil? ? @query.first : super
      end

      def count
        @query.count
      end

      private def fetch
        @result_cache = @query.execute
      end
    end
  end
end
