module Marten
  module Template
    abstract class ContextProducer
      # Context producer that adds the HTTP request object to the context, in a `request` variable.
      class Request < ContextProducer
        def produce(request : HTTP::Request? = nil)
          return if request.nil?

          {"request" => request.not_nil!}
        end
      end
    end
  end
end
