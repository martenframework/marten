module Marten
  module Core
    module Validator
      # Image validator.
      module Image
        extend self

        # Returns `true` if the passed IO corresponds to a valid image.
        def self.valid?(io : IO) : Bool
          __marten_defined?(::Vips) do
            return with_rewound_io(io) do
              Vips::Image.new_from_buffer(io, "")
              true
            rescue Vips::VipsException
              false
            end
          end

          false
        end

        private def with_rewound_io(io, &)
          io.rewind
          yield
        ensure
          io.rewind
        end
      end
    end
  end
end
