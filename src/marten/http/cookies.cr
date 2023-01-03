require "./cookies/**"

module Marten
  module HTTP
    # Represents a set of cookies.
    class Cookies
      include Enumerable({String, Array(String)})

      @encrypted : SubStore::Encrypted? = nil
      @signed : SubStore::Signed? = nil

      def initialize(@cookies : ::HTTP::Cookies)
        @set_cookies = [] of ::HTTP::Cookie
      end

      def initialize
        @cookies = ::HTTP::Cookies.new
        @set_cookies = [] of ::HTTP::Cookie
      end

      # Returns true if the other cookies object corresponds to the current cookies.
      def ==(other : self)
        super || (to_stdlib == other.to_stdlib)
      end

      # Returns the value associated with the passed cookie name.
      def [](name : String | Symbol)
        cookies[name.to_s].value
      end

      # Returns the value associated with the passed cookie name or `nil` if the cookie is not present.
      def []?(name : String | Symbol)
        cookies[name.to_s]?.try(&.value)
      end

      # Allows to set a new cookie associated with the specified `name`.
      #
      # The string representation of the passed `value` object will be used as the cookie value.
      def []=(name, value)
        set(name, value)
      end

      # Deletes a specific cookie and return its value, or `nil` if the cookie does not exist.
      #
      # Appart from the name of the cookie to delete, this method allows to define some additional cookie properties:
      #
      #   * the cookie `path`
      #   * the associated `domain` (useful in order to define cross-domain cookies)
      #   * the `same_site` policy (accepted values are `"lax"` or `"strict"`)
      #
      # The `path`, `domain`, and `same_site` values should always be the same that were used to create the cookie.
      # Otherwise the cookie might not be deleted properly.
      def delete(
        name : String | Symbol,
        path : String = "/",
        domain : String? = nil,
        same_site : Nil | String | Symbol = nil
      ) : String?
        if raw_cookie = cookies.delete(name.to_s)
          deleted_cookie_value = raw_cookie.value

          # Removing a cookie involves setting a cookie with the same name and a past expiry.
          set_cookies << ::HTTP::Cookie.new(
            name: name.to_s,
            value: "",
            expires: 1.year.ago,
            path: path,
            domain: domain,
            samesite: same_site.nil? ? nil : ::HTTP::Cookie::SameSite.parse(same_site.to_s)
          )

          deleted_cookie_value
        end
      end

      def each(&)
        cookies.each do |cookie|
          yield({cookie.name, cookie.value})
        end
      end

      # Returns the encrypted cookies store.
      #
      # The returned object allows to set or fetch encrypted cookies. This means that whenever a cookie is requested
      # from this store, the raw value of this cookie will be decrypted. This is useful to create cookies whose values
      # can't be read nor tampered by users.
      #
      # ```
      # cookies.encrypted["foo"] = "bar"
      # cookies.encrypted["foo"] # => "bar"
      # ```
      def encrypted
        @encrypted ||= SubStore::Encrypted.new(self)
      end

      # Returns the value associated with the passed cookie name, or the passed `default` if the cookie is not present.
      def fetch(name : String | Symbol, default = nil)
        fetch(name) { default }
      end

      # Returns the value associated with the passed cookie name, or calls a block with the name when not found.
      def fetch(name : String | Symbol, &)
        self[name]? || yield name
      end

      # Returns `true` if the cookie with the provided name exists.
      def has_key?(name : String | Symbol)
        cookies.has_key?(name.to_s)
      end

      # Allows to set a new cookie.
      #
      # The string representation of the passed `value` object will be used as the cookie value. Appart from the cookie
      # name and value, this method allows to define some additional cookie properties:
      #
      #   * the cookie expiry datetime (`expires` argument)
      #   * the cookie `path`
      #   * the associated `domain` (useful in order to define cross-domain cookies)
      #   * whether or not the cookie should be sent for HTTPS requests only (`secure` argument)
      #   * whether or not client-side scripts should have access to the cookie (`http_only` argument)
      #   * the `same_site` policy (accepted values are `"lax"` or `"strict"`)
      def set(
        name : String | Symbol,
        value,
        expires : Time? = nil,
        path : String = "/",
        domain : String? = nil,
        secure : Bool = false,
        http_only : Bool = false,
        same_site : Nil | String | Symbol = nil
      ) : Nil
        new_cookie = ::HTTP::Cookie.new(
          name: name.to_s,
          value: value.to_s,
          expires: expires,
          path: path,
          domain: domain,
          secure: secure,
          http_only: http_only,
          samesite: same_site.nil? ? nil : ::HTTP::Cookie::SameSite.parse(same_site.to_s)
        )

        cookies << new_cookie
        set_cookies << new_cookie
      end

      # Returns the signed cookies store.
      #
      # The returned object allows to set or fetch signed cookies. This means that whenever a cookie is requested from
      # this store, the signed representation of the corresponding value will be verified. This is useful to create
      # cookies that can't be tampered by users.
      #
      # ```
      # cookies.signed["foo"] = "bar"
      # cookies.signed["foo"] # => "bar"
      # ```
      def signed
        @signed ||= SubStore::Signed.new(self)
      end

      # :nodoc:
      def to_stdlib
        cookies
      end

      # Returns `true` if there are no cookies.
      delegate empty?, to: cookies

      # Returns the number of cookies.
      delegate size, to: cookies

      protected getter set_cookies

      private getter cookies
    end
  end
end
