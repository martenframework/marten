module Marten
  module HTTP
    module Params
      # Represents the parsed content of a request's body, including both non-file and file inputs.
      class Data < Base
        # :nodoc:
        alias Value = String | UploadedFile

        # :nodoc:
        alias RawHash = Hash(String, Array(String) | Array(UploadedFile) | Array(Value))

        def initialize(@params : RawHash)
          if !Marten.settings.request_max_parameters.nil? && size > Marten.settings.request_max_parameters.as(Int32)
            raise Errors::TooManyParametersReceived.new("The number of parameters that were received is too large")
          end
        end
      end
    end
  end
end
