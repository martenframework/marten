require "./concerns/record_listing"
require "./template"

module Marten
  module Handlers
    # Handler allowing to list model records.
    #
    # This base handler can be used to easily expose a list of model records:
    #
    # ```
    # class MyHandler < Marten::Handlers::RecordList
    #   template_name "my_template"
    #   model Post
    # end
    # ```
    #
    # Optionally, it is possible to configure that records should be paginated:
    #
    # ```
    # class MyHandler < Marten::Handlers::RecordList
    #   template_name "my_template"
    #   model Post
    #   page_size 12
    # end
    # ```
    #
    # When records are paginated, a `Marten::DB::Query::Page` will be exposed in the template context (instead of the
    # raw query set).
    class RecordList < Template
      include RecordListing

      # Returns the name to use to include the record list into the template context (defaults to `records`).
      class_getter list_context_name : String = "records"

      before_render :add_records_to_context

      # Allows to configure the name to use to include the list of records into the template context.
      def self.list_context_name(name : String | Symbol)
        @@list_context_name = name.to_s
      end

      private def add_records_to_context : Nil
        records = self.class.page_size.nil? ? queryset : paginate_queryset
        context[self.class.list_context_name] = records
      end
    end
  end
end
