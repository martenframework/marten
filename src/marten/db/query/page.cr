module Marten
  module DB
    module Query
      # A page resulting from a pagination operation.
      class Page(M)
        include Enumerable(M)

        # Returns the page number.
        getter number

        def initialize(@records : Array(M), @number : Int32, @paginator : Paginator(M))
        end

        # :nodoc:
        def accumulate
          raise NotImplementedError.new("#accumulate is not supported for pages")
        end

        # Returns the number of records in the page.
        def count
          size
        end

        # Returns `true` if there is a next page.
        def next_page?
          number < paginator.pages_count
        end

        # Returns the next page number, or `nil` if there is no next page.
        def next_page_number
          (number + 1) if next_page?
        end

        # Returns `true` if there is a previous page.
        def previous_page?
          number > 1
        end

        # Returns the previous page number, or `nil` if there is no previous page.
        def previous_page_number
          (number - 1) if previous_page?
        end

        # :nodoc:
        def product
          raise NotImplementedError.new("#product is not supported for pages")
        end

        # :nodoc:
        def sum
          raise NotImplementedError.new("#sum is not supported for pages")
        end

        # :nodoc:
        def to_h
          raise NotImplementedError.new("#to_h is not supported for pages")
        end

        delegate each, to: @records

        macro finished
          {% model_types = Marten::DB::Model.all_subclasses.reject(&.abstract?).map(&.name) %}
          {% if model_types.size > 0 %}
            alias Any = {% for t, i in model_types %}Page({{ t }}){% if i + 1 < model_types.size %} | {% end %}{% end %}
          {% else %}
            alias Any = Nil
          {% end %}
        end

        private getter paginator
      end
    end
  end
end
