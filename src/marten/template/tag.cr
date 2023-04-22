require "./tag/**"

module Marten
  module Template
    module Tag
      @@registry = {} of String => Base.class

      # Returns the tag class corresponding to the passed `tag_name`.
      #
      # If no tag can be found, a `Marten::Template::Errors::InvalidSyntax` exception is raised.
      def self.get(tag_name : String | Symbol)
        registry[tag_name.to_s]
      rescue KeyError
        raise Errors::InvalidSyntax.new("Unknown tag with name '#{tag_name}'")
      end

      # Allows to register a new tag.
      def self.register(tag_name : String | Symbol, tag_klass : Base.class)
        @@registry[tag_name.to_s] = tag_klass
      end

      # Returns the current registry of template tags.
      def self.registry
        @@registry
      end

      register "asset", Asset
      register "assign", Assign
      register "block", Block
      register "cache", Cache
      register "csrf_token", CsrfToken
      register "extend", Extend
      register "for", For
      register "if", If
      register "include", Include
      register "local_time", LocalTime
      register "spaceless", Spaceless
      register "super", Super
      register "translate", Translate
      register "trans", Translate
      register "t", Translate
      register "url", Url
      register "verbatim", Verbatim
    end
  end
end
