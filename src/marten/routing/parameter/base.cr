module Marten
  module Routing
    module Parameter
      abstract class Base
        # Returns the string representation of the specified route parameter object.
        #
        # Note that this method can either return a string or `nil`: `nil` means that the passed value cannot be
        # serialized properly, which will make any URL reverse resolution fail with a
        # `Marten::Routing::Errors::NoReverseMatch` error.
        abstract def dumps(value) : Nil | ::String

        # Parses a raw string parmater and returns the corresponding Crystal object.
        #
        # The returned object is the one that will be forwarded to the handler in the route parameters hash.
        abstract def loads(value : ::String)

        # Returns the `Regex` object to use to match parameters when routes are processed.
        abstract def regex : Regex
      end
    end
  end
end
