module Marten
  module HTTP
    # Represents a Content-Security-Policy response header.
    #
    # This class can be leveraged to configure the value of the HTTP Content-Security-Policy response header and enhance
    # protection against cross-site scripting (XSS) and injection attacks.
    #
    # ```
    # policy = Marten::HTTP::ContentSecurityPolicy.new do |csp|
    #   csp.default_src = {:self, "example.com"}
    # end
    #
    # policy.build # => "default-src 'self' example.com"
    # ```
    class ContentSecurityPolicy
      @directives = {} of String => Array(String) | Bool

      # Returns the policy directives.
      getter directives

      def initialize(&)
        yield self
      end

      def initialize
      end

      def initialize(@directives : Hash(String, Array(String) | Bool))
      end

      def block_all_mixed_content=(enabled : Bool)
        if enabled
          @directives["block-all-mixed-content"] = true
        else
          @directives.delete("block-all-mixed-content")
        end
      end

      def build(nonce : String? = nil, nonce_directives : Array(String)? = nil)
        nonce_directives ||= Marten.settings.content_security_policy.nonce_directives
        build_directives(nonce, nonce_directives).join("; ")
      end

      def clone
        self.class.new(directives.clone)
      end

      def upgrade_insecure_requests=(enabled : Bool)
        if enabled
          @directives["upgrade-insecure-requests"] = true
        else
          @directives.delete("upgrade-insecure-requests")
        end
      end

      # :nodoc:
      macro def_directive(directive)
        {% directive_id = directive.id.gsub(/_/, "-") %}

        # Allows to set the {{ directive_id }} directive or remove it (if a `nil` value is specified).
        def {{ directive.id }}=(value : Array | Nil | String | Symbol | Tuple)
          return @directives.delete("{{ directive_id }}") if value.nil?

          @directives["{{ directive_id }}"] = case value
          when Array, Tuple
            apply_value_mappings(value)
          when String
            [value]
          when Symbol
            [apply_value_mapping(value)]
          end.not_nil!
        end
      end

      def_directive :base_uri
      def_directive :child_src
      def_directive :connect_src
      def_directive :default_src
      def_directive :font_src
      def_directive :form_action
      def_directive :frame_ancestors
      def_directive :frame_src
      def_directive :img_src
      def_directive :manifest_src
      def_directive :media_src
      def_directive :navigate_to
      def_directive :object_src
      def_directive :plugin_types
      def_directive :prefetch_src
      def_directive :report_to
      def_directive :report_uri
      def_directive :require_sri_for
      def_directive :sandbox
      def_directive :script_src
      def_directive :script_src_attr
      def_directive :script_src_elem
      def_directive :style_src
      def_directive :style_src_attr
      def_directive :style_src_elem
      def_directive :worker_src

      private VALUE_MAPPINGS = {
        self:             "'self'",
        unsafe_eval:      "'unsafe-eval'",
        unsafe_inline:    "'unsafe-inline'",
        none:             "'none'",
        http:             "http:",
        https:            "https:",
        data:             "data:",
        mediastream:      "mediastream:",
        allow_duplicates: "'allow-duplicates'",
        blob:             "blob:",
        filesystem:       "filesystem:",
        report_sample:    "'report-sample'",
        script:           "'script'",
        strict_dynamic:   "'strict-dynamic'",
        ws:               "ws:",
        wss:              "wss:",
      }

      private def apply_value_mapping(value : Symbol) : String
        VALUE_MAPPINGS.fetch(value) { value.to_s }
      end

      private def apply_value_mappings(values : Array | Tuple) : Array(String)
        values.map do |value|
          case value
          when Symbol
            apply_value_mapping(value)
          when String
            value
          else
            value.to_s
          end
        end.to_a
      end

      private def build_directives(nonce : String?, nonce_directives : Array(String)?) : Array(String)
        @directives.compact_map do |directive, sources|
          next unless sources

          String.build do |s|
            s << if sources.is_a?(Array)
              "#{directive} #{sources.join(' ')}"
            elsif sources
              directive
            end

            if !nonce.nil? && use_nonce_for_directive?(directive, nonce_directives)
              s << " 'nonce-#{nonce}'"
            end
          end
        end
      end

      private def use_nonce_for_directive?(directive : String, nonce_directives : Array(String)?) : Bool
        return false if nonce_directives.nil?

        nonce_directives.includes?(directive)
      end
    end
  end
end
