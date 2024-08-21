module Marten
  module Core
    # The Sluggable module provides functionality for generating URL-friendly slugs from strings.
    module Sluggable
      extend self

      NON_ALPHANUMERIC_RE  = /[^\w\s-]/
      WHITESPACE_HYPHEN_RE = /[-\s]+/
      NON_ASCII_RE         = /[^\x00-\x7F]/

      # Generates a slug from the given value, ensuring the resulting slug does not exceed the specified max_size.
      #
      # The slug is created by:
      # 1. Removing non-alphanumeric characters (except whitespace and hyphens).
      # 2. Converting the string to lowercase.
      # 3. Replacing sequences of whitespace and hyphens with a single hyphen.
      # 4. Removing non-ASCII characters.
      # 5. Truncating the slug to fit within the max_size, minus the size of a randomly generated suffix.
      # 6. Stripping trailing hyphens and underscores of the slug without suffix, and appending the suffix.
      def generate_slug(value, max_size)
        suffix = "-#{Random::Secure.hex(4)}"

        slug = value.gsub(NON_ALPHANUMERIC_RE, "").downcase
        slug = slug.gsub(WHITESPACE_HYPHEN_RE, "-")
        slug = slug.gsub(NON_ASCII_RE, "")

        slug[...(max_size - suffix.size)].strip("-_") + suffix
      end
    end
  end
end
