require "./concerns/record_retrieving"
require "./template"

module Marten
  module Handlers
    # Handler allowing to delete a specific model record.
    #
    # This handler can be used to delete an existing model record for POST requests. Optionally the handler can be
    # accessed with GET request and a template can be displayed in this case; this allows to show a confirmation page to
    # users before deleting the record:
    #
    # ```
    # class ArticleDeleteHandler < Marten::Handlers::RecordDelete
    #   model MyModel
    #   template_name "article_delete.html"
    #   success_route_name "article_delete_success"
    # end
    # ```
    #
    # It should be noted that the redirect response issued will be a 302 (found).
    #
    # The `#template_name` class method allows to define the name of the template to use to render a deletion
    # confirmation page while the `#success_route_name` method can be used to specify the name of a route to redirect to
    # once the deletion is complete. Alternatively, the `#sucess_url` class method can be used to provide a raw URL to
    # redirect to. The same method can also be overridden at the instance level in order to rely on a custom logic to
    # generate the sucess URL to redirect to.
    class RecordDelete < Template
      include RecordRetrieving

      # Returns the name to use to include the model record into the template context (defaults to `record`).
      class_getter record_context_name : String = "record"

      # Returns the route name that should be resolved to produce the URL to redirect to after deleting the record.
      #
      # Defaults to `nil`.
      class_getter success_route_name : String?

      # Returns the configured raw URL to redirect to after deleting the record.
      #
      # Defaults to `nil`.
      class_getter success_url : String?

      before_render :add_record_to_context

      # Allows to configure the name to use to include the model record into the template context.
      def self.record_context_name(name : String | Symbol)
        @@record_context_name = name.to_s
      end

      # Allows to set the route name that should be resolved to produce the URL to redirect to after the deletion.
      def self.success_route_name(success_route_name : String?)
        @@success_route_name = success_route_name
      end

      # Allows to configure a raw URL to redirect to after the deletion
      def self.success_url(success_url : String?)
        @@success_url = success_url
      end

      def post
        perform_deletion
        HTTP::Response::Found.new(success_url)
      end

      # Returns the URL to redirect to after the deletion is complete.
      #
      # By default, the URL will be determined from the configured `#success_url` and `#success_route_name` values. This
      # method can be overridden on subclasses in order to define any arbitrary logics that might be necessary in order
      # to determine the deletion success URL.
      def success_url
        (
          self.class.success_url ||
            (self.class.success_route_name && reverse(self.class.success_route_name.not_nil!))
        ).not_nil!
      end

      private def add_record_to_context : Nil
        context[self.class.record_context_name] = record
      end

      private def perform_deletion
        record.delete
      end
    end
  end
end
