module Marten
  module Conf
    class GlobalSettings
      # Allows to configure emailing-related settings.
      class Emailing
        @backend : Marten::Emailing::Backend::Base = Marten::Emailing::Backend::Development.new
        @from_address = Marten::Emailing::Address.new("webmaster@localhost")

        # Returns the backend used to deliver emails.
        getter backend

        # Returns the default from address used in emails.
        getter from_address

        # Allows to set the backend used to deliver emails.
        def backend=(backend : Marten::Emailing::Backend::Base)
          @backend = backend
        end

        # Allows to set the default from address used in emails.
        def from_address=(address : Marten::Emailing::Address | String | Symbol)
          @from_address = case address
                          when Marten::Emailing::Address
                            address.as(Marten::Emailing::Address)
                          else
                            Marten::Emailing::Address.new(address.to_s)
                          end
        end
      end
    end
  end
end
