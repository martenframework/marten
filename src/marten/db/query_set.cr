module Marten
  module DB
    class QuerySet(Model)
      include Enumerable(Model)

      @result_cache : Array(Model)?

      def initialize(@query = SQL::Query(Model).new)
      end

      def each
        fetch if @result_cache.nil?
        @result_cache.not_nil!.each do |r|
          yield r
        end
      end

      def all
        clone
      end

      def first
        @result_cache.nil? ? @query.first : super
      end

      def exists?
        @result_cache.nil? ? @query.exists? : !@result_cache.not_nil!.empty?
      end

      def count
        @query.count
      end

      protected def clone
        cloned = self.class.new(query: @query.clone)
        cloned
      end

      private def fetch
        @result_cache = @query.execute
      end
    end
  end
end
