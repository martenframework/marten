require "./concerns/*"

module Marten
  module HTTP
    module Params
      # Represents the parsed content of a request's body, including both non-file and file inputs.
      class Data
        # :nodoc:
        alias Value = JSON::Any | String | UploadedFile

        # :nodoc:
        alias Values = Array(Value)

        # :nodoc:
        alias RawHash = Hash(String, Array(String) | Array(JSON::Any) | Array(UploadedFile) | Values)

        include Enumerable({String, Array(String) | Array(JSON::Any) | Array(UploadedFile) | Values})
        include Core

        def initialize
          @params = RawHash.new
        end

        def initialize(@params : RawHash)
          if !Marten.settings.request_max_parameters.nil? && size > Marten.settings.request_max_parameters.as(Int32)
            raise Errors::TooManyParametersReceived.new("The number of parameters that were received is too large")
          end
        end
      end
    end
  end
end
