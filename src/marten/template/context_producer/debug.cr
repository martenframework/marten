module Marten
  module Template
    abstract class ContextProducer
      # Context producer that adds a `debug` variable based on the whether debug mode is enabled or not.
      class Debug < ContextProducer
        def produce(request : HTTP::Request? = nil)
          {"debug" => Marten.settings.debug}
        end
      end
    end
  end
end
