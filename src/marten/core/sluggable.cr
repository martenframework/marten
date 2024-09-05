module Marten
  module Core
    # The Sluggable module provides functionality for generating URL-friendly slugs from strings.
    module Sluggable
      private NON_ALPHANUMERIC_RE  = /[^\w\s-]/
      private WHITESPACE_HYPHEN_RE = /[-\s]+/
      private NON_ASCII_RE         = /[^\x00-\x7F]/

      # Generates a slug from the given value, ensuring the resulting slug does not exceed the specified max_size.
      #
      # The slug is created by:
      # 1. Removing non-alphanumeric characters (except whitespace and hyphens).
      # 2. Converting the string to lowercase.
      # 3. Replacing sequences of whitespace and hyphens with a single hyphen.
      # 4. Removing non-ASCII characters.
      # 5. Stripping trailing hyphens and underscores of the slug.
      # 6. Truncate the slug to the maximum size
      def generate_slug(value, max_size)
        slug = value.gsub(NON_ALPHANUMERIC_RE, "").downcase
        slug = slug.gsub(WHITESPACE_HYPHEN_RE, "-")
        slug = slug.gsub(NON_ASCII_RE, "")
        slug[...(max_size)].strip("-_")
      end
    end
  end
end
