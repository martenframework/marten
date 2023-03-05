require "./filter/**"

module Marten
  module Template
    module Filter
      @@registry = {} of String => Base

      # Returns the filter object corresponding to the passed `filter_name`.
      #
      # If no filter can be found, a `Marten::Template::Errors::InvalidSyntax` exception is raised.
      def self.get(filter_name : String | Symbol)
        registry[filter_name.to_s]
      rescue KeyError
        raise Errors::InvalidSyntax.new("Unknown filter with name '#{filter_name}'")
      end

      # Allows to register a new filter.
      def self.register(filter_name : String | Symbol, filter_klass : Base.class)
        @@registry[filter_name.to_s] = filter_klass.new
      end

      # Returns the current registry of template filters.
      def self.registry
        @@registry
      end

      register "capitalize", Capitalize
      register "default", Default
      register "downcase", DownCase
      register "join", Join
      register "linebreaks", LineBreaks
      register "safe", Safe
      register "size", Size
      register "split", Split
      register "upcase", UpCase
    end
  end
end
