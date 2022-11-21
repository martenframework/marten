module Marten
  module Template
    abstract class ContextProducer
      # Context producers that adds a `flash` variable for the flash store in the context if a request is present.
      class Flash < ContextProducer
        def produce(request : HTTP::Request? = nil)
          return if request.nil? || !request.flash?

          {"flash" => request.not_nil!.flash}
        end
      end
    end
  end
end
