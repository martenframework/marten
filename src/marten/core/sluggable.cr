module Marten
  module Core
    # The Sluggable module provides functionality for generating URL-friendly slugs from strings.
    module Sluggable
      private NON_ALPHANUMERIC_RE  = /[^\p{L}\p{N}\p{So}\s-]/
      private WHITESPACE_HYPHEN_RE = /[-\s]+/

      # Generates a slug from the given value, ensuring the resulting slug does not exceed the specified max_size.
      #
      # The slug is created by:
      # 1. Removing non-alphanumeric characters (except for Unicode letters, numbers, symbols, whitespace, and hyphens).
      # 2. Converting the string to lowercase.
      # 3. Replacing sequences of whitespace and hyphens with a single hyphen.
      # 4. Stripping trailing hyphens and underscores from the slug.
      # 5. Truncating the slug to the specified max_size.
      def generate_slug(value, max_size)
        slug = value.gsub(NON_ALPHANUMERIC_RE, "").downcase
        slug = slug.gsub(WHITESPACE_HYPHEN_RE, "-")
        slug[...(max_size)].strip("-_")
      end
    end
  end
end
