module Marten
  module Routing
    module Rule
      class Path < Base
        @path_info : Routing::Path::Spec::Base
        @reversers : Array(Reverser)?

        getter handler
        getter name
        getter path

        def initialize(@path : String | TranslatedPath, @handler : Marten::Handlers::Base.class, @name : String)
          @path_info = path_to_path_info(path, regex_suffix: "$")
        end

        def resolve(path : String) : Match?
          match = @path_info.resolve(path)
          return if match.nil?

          Match.new(handler: @handler, kwargs: match.parameters, rule: self)
        end

        protected def reversers : Array(Reverser)
          @reversers ||= [@path_info.reverser(@name)]
        end
      end
    end
  end
end
