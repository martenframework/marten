module Marten
  module Handlers
    # Provides the ability to retrieve a list of model records.
    module RecordListing
      macro included
        # Returns the name of the page number parameter.
        class_getter page_number_param : String = "page"

        # Returns the page size to use if records should be paginated.
        class_getter page_size : Int32 | Nil

        # Returns the array of fields to use to order the records.
        class_getter ordering : Array(String) | Nil

        extend Marten::Handlers::RecordListing::ClassMethods
      end

      module ClassMethods
        # Allows to configure the name of the page number parameter.
        def page_number_param(param : String | Symbol)
          @@page_number_param = param.to_s
        end

        # Allows to configure the page size to use if records should be paginated.
        #
        # If the specified page size is `nil`, it means that records won't be paginated.
        def page_size(page_size : Int32 | Nil)
          @@page_size = page_size
        end

        # Allows to configure the list of fields to use to order the records.
        def ordering(*fields : String | Symbol)
          @@ordering = fields.map(&.to_s).to_a
        end

        # Allows to configure the list of fields to use to order the records.
        def ordering(fields : Array(String | Symbol))
          @@ordering = fields.map(&.to_s)
        end
      end

      # Allows to configure the model class that should be used to retrieve the list of records.
      #
      # This macro should only be used in situations where the `queryset` macro is not used.
      macro model(model_klass)
        # Returns the model used to list the records.
        def model
          {{ model_klass }}
        end
      end

      # Allows to configure the query set that should be used to retrieve the list of records.
      #
      # This macro should only be used in situations where the `model` macro is not used.
      macro queryset(queryset)
        # Returns the queryset used to list the records.
        def queryset
          if ordering = self.class.ordering
            {{ queryset }}.order(ordering)
          else
            {{ queryset }}
          end
        end
      end

      # Returns the model used to list the records.
      def model
        raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a model class via the '::model' macro or by overriding the " \
          "'#model' method"
        )
      end

      # Returns a page resulting from the pagination of the queryset for the current page.
      def paginate_queryset
        raw_page_number = params[self.class.page_number_param]? || request.query_params[self.class.page_number_param]?

        page_number = begin
          raw_page_number.as?(Int32 | String).try(&.to_i32) || 1
        rescue ArgumentError
          1
        end

        queryset.paginator(self.class.page_size.not_nil!).page(page_number)
      end

      # Returns the queryset used to retrieve the records displayed by the handler.
      def queryset
        if ordering = self.class.ordering
          model.all.order(ordering)
        else
          model.all
        end
      end
    end
  end
end
