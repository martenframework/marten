module Marten
  module Views
    # Provides the ability to retrieve a list of model records.
    module RecordListing
      macro included
        # Returns the configured model class.
        class_getter model : DB::Model.class | Nil

        # Returns the name of the page number parameter.
        class_getter page_number_param : String = "page"

        # Returns the page size to use if records should be paginated.
        class_getter page_size : Int32 | Nil

        extend Marten::Views::RecordListing::ClassMethods
      end

      module ClassMethods
        # Allows to configure the model class that should be used to retrieve the list record.
        def model(model : DB::Model.class | Nil)
          @@model = model
        end

        # Allows to configure the name of the page number parameter.
        def page_number_param(param : String | Symbol)
          @@page_number_param = param.to_s
        end

        # Allows to configure the page size to use if records should be paginated.
        #
        # If the specified page size is `nil`, it means that records won't be paginated.
        def page_size(page_size : Int | Nil)
          @@page_size = page_size.try(&.to_i32)
        end
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

      # Returns the queryset used to retrieve the record displayed by the view.
      def queryset
        self.class.model.not_nil!.all
      end
    end
  end
end
