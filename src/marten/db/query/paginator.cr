module Marten
  module DB
    module Query
      # A query set paginator.
      #
      # Paginators can be used to paginate the records that are targeted by a specific query set:
      #
      # ```
      # query_set = Post.all
      # query_set.paginator.page(2)
      # ```
      class Paginator(M)
        class EmptyPageError < Exception; end

        @pages_count : Int32? = nil

        getter queryset
        getter page_size

        def initialize(@queryset : Set(M), @page_size : Int32)
        end

        # Returns a specific page.
        #
        # This method returns the `Marten::DB::Query::Page` object corresponding to the passed `number`. If the page
        # number does not correspond to any existing page, the latest page is returned.
        def page(number : Int)
          page!(number)
        rescue EmptyPageError
          page!(pages_count)
        end

        # Returns a specific page.
        #
        # This method returns the `Marten::DB::Query::Page` object corresponding to the passed `number`. If the page
        # number does not correspond to any existing page, a `Marten::DB::Query::Paginator::EmptyPageError` exception is
        # raised.
        def page!(number : Int)
          validate_number(number)
          range_beginning = (number - 1) * page_size
          range_end = range_beginning + page_size
          Page(M).new(queryset[range_beginning...range_end].to_a, number, self)
        end

        # Returns the number of pages.
        def pages_count
          @pages_count ||= ([1, queryset.size].max / page_size).ceil.to_i32
        end

        private def validate_number(number)
          raise EmptyPageError.new("Page numbers cannot be less than 1") if number < 1
          raise EmptyPageError.new("Page with number #{number} contains no results") if number > pages_count
        end
      end
    end
  end
end
