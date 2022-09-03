module Marten
  module Template
    # A template context producer.
    #
    # Template context producers allow to contribute values to a template context, that can be optionally associated
    # an HTTP request (if the template is rendered for a specific request for example). For example, a context producer
    # can be used to always include the current user in the template context based on the current request, some debug
    # information, etc.
    abstract class ContextProducer
      # Returns a hash of values to include in a template context.
      #
      # The method must return a hash or named tuple if there are values to return, otherwise it can also return `nil`
      # if it can't produce any values.
      abstract def produce(request : HTTP::Request? = nil)
    end
  end
end
