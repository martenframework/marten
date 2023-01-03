require "./set"

module Marten
  module DB
    module Query
      # Represents a raw query set.
      #
      # A raw query set allows to easily map the results of a raw SQL statement into corresponding model instances and
      # allows to iterate over them (like a regular query set).
      class RawSet(M)
        include Enumerable(M)

        @result_cache : Array(M)?

        # :nodoc:
        getter query

        def initialize(query : String, params : Array(::DB::Any) | Hash(String, ::DB::Any), using : String?)
          @query = SQL::RawQuery(M).new(query: query, params: params, using: using)
        end

        def initialize(@query = SQL::RawQuery(M).new)
        end

        # Returns the record at the given index.
        #
        # If no record can be found at the given index, then an `IndexError` exception is raised.
        def [](index : Int)
          raise_negative_indexes_not_supported if index < 0

          to_a[index]
        end

        # Returns the record at the given index.
        #
        # `nil` is returned if no record can be found at the given index.
        def []?(index : Int)
          self[index]
        rescue IndexError
          nil
        end

        # Returns the records corresponding to the passed range.
        #
        # If no records match the passed range, an `IndexError` exception is raised.
        def [](range : Range)
          raise_negative_indexes_not_supported if !range.begin.nil? && range.begin.not_nil! < 0
          raise_negative_indexes_not_supported if !range.end.nil? && range.end.not_nil! < 0

          to_a[range]
        end

        # Returns the records corresponding to the passed range.
        #
        # `nil` is returned if no records match the passed range.
        def []?(range : Range)
          self[range]
        rescue IndexError
          nil
        end

        # :nodoc:
        def accumulate
          raise NotImplementedError.new("#accumulate is not supported for raw query sets")
        end

        # Returns the number of records that are targeted by the current raw query set.
        def count
          fetch if @result_cache.nil?
          @result_cache.not_nil!.size
        end

        # Allows to iterate over the records that are targeted by the current query set.
        #
        # This method can be used to define a block that iterates over the records that are targeted by a query set:
        #
        # ```
        # Post.all.each do |post|
        #   # Do something
        # end
        # ```
        def each(&)
          fetch if @result_cache.nil?
          @result_cache.not_nil!.each do |r|
            yield r
          end
        end

        # :nodoc:
        def product
          raise NotImplementedError.new("#product is not supported for raw query sets")
        end

        # Returns the number of records that are targeted by the current raw query set.
        def size
          count
        end

        # :nodoc:
        def sum
          raise NotImplementedError.new("#sum is not supported for raw query sets")
        end

        # :nodoc:
        def to_h
          raise NotImplementedError.new("#to_h is not supported for raw query sets")
        end

        # Allows to define which database alias should be used when evaluating the raw query set.
        def using(db : String | Symbol)
          qs = clone
          qs.query.using = db.to_s
          qs
        end

        protected def clone(other_query = nil)
          RawSet(M).new(query: other_query.nil? ? @query.clone : other_query.not_nil!)
        end

        protected def fetch
          @result_cache = @query.execute
        end

        private def raise_negative_indexes_not_supported
          raise Errors::UnmetQuerySetCondition.new("Negative indexes are not supported")
        end
      end
    end
  end
end
