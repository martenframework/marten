require "./spec_helper"

describe Marten::Conf::GlobalSettings::ContentSecurityPolicy do
  {% for directive in [
                        "base_uri", "child_src", "connect_src", "default_src", "font_src", "form_action",
                        "frame_ancestors", "frame_src", "img_src", "manifest_src", "media_src", "navigate_to",
                        "object_src", "plugin_types", "prefetch_src", "report_to", "report_uri", "require_sri_for",
                        "sandbox", "script_src", "script_src_attr", "script_src_elem", "style_src", "style_src_attr",
                        "style_src_elem", "worker_src",
                      ] %}
  describe "\#{{ directive.id }}=" do
    it "is delegated to the default policy object" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new

      csp_conf.{{ directive.id }} = "value"

      csp_conf.default_policy.directives[{{ directive.gsub(/_/, "-") }}].should eq ["value"]
    end
  end
  {% end %}

  {% for directive in ["block_all_mixed_content", "upgrade_insecure_requests"] %}
  describe "\#{{ directive.id }}=" do
    it "is delegated to the default policy object" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new

      csp_conf.{{ directive.id }} = true

      csp_conf.default_policy.directives[{{ directive.gsub(/_/, "-") }}].should be_true
    end
  end
  {% end %}

  describe "#default_policy" do
    it "returns a Content-Security-Policy object initialized with the right directives" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new

      csp_conf.default_policy.should be_a Marten::HTTP::ContentSecurityPolicy
      csp_conf.default_policy.directives["default-src"].should eq ["'self'"]
    end
  end

  describe "#default_policy=" do
    it "allows to set the default Content-Security-Policy object" do
      csp = Marten::HTTP::ContentSecurityPolicy.new
      csp.default_src = [:self, "other"]

      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new
      csp_conf.default_policy = csp

      csp_conf.default_policy.should eq csp
      csp_conf.default_policy.directives["default-src"].should eq ["'self'", "other"]
    end
  end

  describe "#report_only" do
    it "returns false by default" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new

      csp_conf.report_only.should be_false
    end

    it "returns the configured value" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new
      csp_conf.report_only = true

      csp_conf.report_only.should be_true
    end
  end

  describe "#report_only?" do
    it "returns false by default" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new

      csp_conf.report_only?.should be_false
    end

    it "returns the configured value" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new
      csp_conf.report_only = true

      csp_conf.report_only?.should be_true
    end
  end

  describe "#report_only=" do
    it "allows to set whether policy violations are reported without enforcing it" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new
      csp_conf.report_only = true

      csp_conf.report_only?.should be_true
    end
  end

  describe "#nonce_directives" do
    it "returns the expected directives by default" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new

      csp_conf.nonce_directives.should eq ["script-src", "style-src"]
    end

    it "returns the configured nonce directives" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new
      csp_conf.nonce_directives = ["script-src"]

      csp_conf.nonce_directives.should eq ["script-src"]
    end
  end

  describe "#nonce_directives=" do
    it "allows to set the nonce directives" do
      csp_conf = Marten::Conf::GlobalSettings::ContentSecurityPolicy.new
      csp_conf.nonce_directives = ["script-src"]

      csp_conf.nonce_directives.should eq ["script-src"]
    end
  end
end
