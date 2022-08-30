require "./base"
require "./concerns/*"

module Marten
  module Template
    module Tag
      # The `asset` template tag.
      #
      # The `asset` template tag allows to generate the URL of a given asset. It must be take one argument (the filepath
      # of the asset).
      #
      # For example the following line is a valid usage of the `asset` tag:
      #
      # ```
      # {% asset "app/app.css" %}
      # ```
      #
      # Optionally, resolved asset URLs can be assigned to a specific variable using the `as` keyword:
      #
      # ```
      # {% asset "app/app.css" as my_var %}
      # ```
      class Asset < Base
        include CanExtractKwargs
        include CanSplitSmartly

        @assigned_to : String? = nil

        def initialize(parser : Parser, source : String)
          parts = split_smartly(source)

          if parts.size < 2
            raise Errors::InvalidSyntax.new("Malformed asset tag: at least one argument must be provided")
          end

          @asset_name_expression = FilterExpression.new(parts[1])

          # Identify possible assigned variable name.
          if parts.size > 2 && parts[-2] == "as"
            @assigned_to = parts[-1]
          elsif parts.size > 2
            raise Errors::InvalidSyntax.new("Malformed asset tag: only one argument must be provided")
          end
        end

        def render(context : Context) : String
          asset_name = @asset_name_expression.resolve(context).to_s

          url = Marten.assets.url(asset_name)

          if @assigned_to.nil?
            url
          else
            context[@assigned_to.not_nil!] = url
            ""
          end
        end
      end
    end
  end
end
