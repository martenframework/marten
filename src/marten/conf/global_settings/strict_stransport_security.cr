module Marten
  module Conf
    class GlobalSettings
      # Allows to configure settings related to the Strict-Transport-Security middleware.
      class StrictTransportSecurity
        @include_sub_domains = false
        @max_age : Int32? = nil
        @preload = false

        # Indicates if the `includeSubDomains` directive should be set on the Strict-Transport-Security header.
        getter include_sub_domains

        # Returns the max age to use for the Strict-Transport-Security header.
        #
        # A `nil` value indicates that the Strict-Transport-Security header will not be set.
        getter max_age

        # Indicates if the `preload` directive should be set on the Strict-Transport-Security header.
        getter preload

        # Allows to define if the `includeSubDomains` directive should be set on the Strict-Transport-Security header.
        setter include_sub_domains

        # Allows to set the max age to use for the Strict-Transport-Security header.
        setter max_age

        # Allows to define if the `preload` directive should be set on the Strict-Transport-Security header.
        setter preload
      end
    end
  end
end
