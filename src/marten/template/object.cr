require "./object/**"

module Marten
  module Template
    # Allows to add support for custom classes to template contexts.
    #
    # Including this module in a class will make it "compatible" with the template engine so that instances of this
    # class can be included in context objects.
    module Object
    end
  end
end
