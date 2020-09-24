module Marten
  module Apps
    # Provides the ability for a specific class to have an associated Marten app.
    module Association
      macro included
        # :nodoc:
        def self._marten_app_location
          __DIR__
        end

        macro inherited
          # :nodoc:
          def self._marten_app_location
            __DIR__
          end
        end
      end
    end
  end
end
