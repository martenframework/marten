require "./concerns/*"

module Marten
  module HTTP
    module Params
      # Represents a set of GET parameters, extracted from a request's query string.
      class Query
        # :nodoc:
        alias Value = String

        # :nodoc:
        alias Values = Array(Value)

        # :nodoc:
        alias RawHash = Hash(String, Values)

        include Enumerable({String, Values})
        include Core

        def initialize
          @params = RawHash.new
        end

        def initialize(@params : RawHash)
          if !Marten.settings.request_max_parameters.nil? && size > Marten.settings.request_max_parameters.as(Int32)
            raise Errors::TooManyParametersReceived.new("The number of parameters that were received is too large")
          end
        end

        # Returns a string corresponding to the params in query string format.
        def as_query : String
          String.build do |io|
            builder = ::HTTP::Params::Builder.new(io)
            @params.each do |name, values|
              values.each do |value|
                builder.add(name, value)
              end
            end
          end
        end
      end
    end
  end
end
