require "./field"

module Marten
  module DB
    class QuerySet(Model)
      include Enumerable(Model)

      @result_cache : Array(Model)?

      def initialize(@query = SQL::Query(Model).new)
      end

      def inspect(io)
        results = self[...INSPECT_RESULTS_LIMIT + 1].to_a
        io << "<#{self.class.name} ["
        io << "#{results[...INSPECT_RESULTS_LIMIT].join(", ")}"
        io << ", ...(remaining truncated)..." if results.size > INSPECT_RESULTS_LIMIT
        io << "]>"
      end

      def each
        fetch if @result_cache.nil?
        @result_cache.not_nil!.each do |r|
          yield r
        end
      end

      def [](index : Int)
        raise_negative_indexes_not_supported if index < 0

        return @result_cache.not_nil![index] unless @result_cache.nil?

        qs = clone

        qs.query.offset = index
        qs.query.limit = 1
        qs.fetch
        qs.result_cache.not_nil![0]
      end

      def []?(index : Int)
        self[index]
      rescue IndexError
        nil
      end

      def [](range : Range)
        raise_negative_indexes_not_supported if !range.begin.nil? && range.begin.not_nil! < 0
        raise_negative_indexes_not_supported if !range.end.nil? && range.end.not_nil! < 0

        return @result_cache.not_nil![range] unless @result_cache.nil?

        qs = clone

        offset = range.begin.nil? ? 0 : range.begin.not_nil!
        qs.query.offset = offset

        unless range.end.nil?
          qs.query.limit = range.excludes_end? ? (range.end.not_nil! - offset) : (range.end.not_nil! + 1 - offset)
        end

        qs
      end

      def []?(range : Range)
        self[range]
      rescue IndexError
        nil
      end

      def all
        clone
      end

      def filter(**kwargs)
        filter(Q(Model).new(**kwargs))
      end

      def filter(query : Q(Model))
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

      def order(*fields : String | Symbol)
        qs = clone
        qs.query.order(*fields.map(&.to_s))
        qs
      end

      def reverse
        qs = clone
        qs.query.default_ordering = !@query.default_ordering
        qs
      end

      def size
        count
      end

      protected getter query
      protected getter result_cache

      protected def clone
        cloned = self.class.new(query: @query.clone)
        cloned
      end

      protected def fetch
        @result_cache = @query.execute
      end

      private INSPECT_RESULTS_LIMIT = 20

      private def raise_negative_indexes_not_supported
        raise "Negative indexes are not supported"
      end
    end
  end
end
