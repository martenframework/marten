module Marten
  module Conf
    class GlobalSettings
      # Allows to configure settings related to the Content-Security-Policy middleware.
      class ContentSecurityPolicy
        @default_policy : HTTP::ContentSecurityPolicy
        @nonce_directives : Array(String)? = ["script-src", "style-src"]
        @report_only = false

        # Returns the default Content-Security-Policy.
        getter default_policy

        # Returns an array of directives where a dynamically-generated nonce will be included.
        #
        # For example, if this setting is set to `["script-src"]`, a `nonce-<b64-value>` value will be added to the
        # `script-src` directive.
        getter nonce_directives

        # Indicates whether policy violations are reported without enforcing it.
        getter report_only

        # :ditto:
        getter? report_only

        # Allows to set the default Content-Security-Policy.
        setter default_policy

        # Allows to set the array of directives where a dynamically-generated nonce will be included.
        setter nonce_directives

        # Allows set whether to report violations of the policy without enforcing it.
        setter report_only

        delegate :base_uri=, to: default_policy
        delegate :block_all_mixed_content=, to: default_policy
        delegate :child_src=, to: default_policy
        delegate :connect_src=, to: default_policy
        delegate :default_src=, to: default_policy
        delegate :font_src=, to: default_policy
        delegate :form_action=, to: default_policy
        delegate :frame_ancestors=, to: default_policy
        delegate :frame_src=, to: default_policy
        delegate :img_src=, to: default_policy
        delegate :manifest_src=, to: default_policy
        delegate :media_src=, to: default_policy
        delegate :navigate_to=, to: default_policy
        delegate :object_src=, to: default_policy
        delegate :plugin_types=, to: default_policy
        delegate :prefetch_src=, to: default_policy
        delegate :report_to=, to: default_policy
        delegate :report_uri=, to: default_policy
        delegate :require_sri_for=, to: default_policy
        delegate :sandbox=, to: default_policy
        delegate :script_src=, to: default_policy
        delegate :script_src_attr=, to: default_policy
        delegate :script_src_elem=, to: default_policy
        delegate :style_src=, to: default_policy
        delegate :style_src_attr=, to: default_policy
        delegate :style_src_elem=, to: default_policy
        delegate :worker_src=, to: default_policy
        delegate :upgrade_insecure_requests=, to: default_policy

        def initialize
          @default_policy = HTTP::ContentSecurityPolicy.new do |csp|
            csp.default_src = :self
          end
        end
      end
    end
  end
end
