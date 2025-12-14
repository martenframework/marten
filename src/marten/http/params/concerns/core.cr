module Marten
  module HTTP
    module Params
      module Core
        # Returns the last value associated with the passed parameter name.
        def [](name : String | Symbol)
          @params[name.to_s].last
        rescue KeyError | IndexError
          raise KeyError.new("Unknown parameter: #{name}")
        end

        # Returns the last value associated with the passed parameter name or `nil` if the parameter is not present.
        def []?(name : String | Symbol)
          @params[name.to_s]?.try &.last
        rescue IndexError
          nil
        end

        # :nodoc:
        def accumulate
          raise NotImplementedError.new("#accumulate is not supported for request params")
        end

        # Returns `true` if the parameter with the provided name exists.
        def has_key?(name : String | Symbol)
          @params.has_key?(name.to_s)
        end

        # Returns the last value for the specified parameter name or fallback to the provided default value (which is
        # `nil` by default).
        def fetch(name : String | Symbol, default = nil)
          self[name]? || default
        end

        # Returns the last value for the specified parameter name or calls the block with the name when not found.
        def fetch(name : String | Symbol, &)
          self[name]? || yield name
        end

        # Returns all the values for a specified parameter name.
        def fetch_all(name : String | Symbol, default = nil)
          @params.fetch(name.to_s, default)
        end

        # :nodoc:
        def product
          raise NotImplementedError.new("#product is not supported for query params")
        end

        # Returns the number of parameters.
        def size
          @params.reduce(0) { |acc, (_, v)| acc + (v.size > 0 ? v.size : 1) }
        end

        # :nodoc:
        def sum
          raise NotImplementedError.new("#sum is not supported for query params")
        end

        delegate :[]=, to: @params

        # Allows to iterate over all the parameters.
        delegate each, to: @params

        # Returns `true` if no parameters are present.
        delegate empty?, to: @params

        # Returns the hash representation of the parameters.
        delegate to_s, to: @params
      end
    end
  end
end
