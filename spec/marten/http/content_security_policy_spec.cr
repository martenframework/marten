require "./spec_helper"

describe Marten::HTTP::ContentSecurityPolicy do
  describe "#new" do
    it "initializes a Content-Security-Policy object" do
      csp = Marten::HTTP::ContentSecurityPolicy.new
      csp.default_src = :self

      csp.directives["default-src"].should eq ["'self'"]
    end

    it "initializes a Content-Security-Policy object with a block" do
      csp = Marten::HTTP::ContentSecurityPolicy.new do |policy|
        policy.default_src = :self
      end

      csp.directives["default-src"].should eq ["'self'"]
    end
  end

  {% for directive in [
                        "base_uri", "child_src", "connect_src", "default_src", "font_src", "form_action",
                        "frame_ancestors", "frame_src", "img_src", "manifest_src", "media_src", "navigate_to",
                        "object_src", "plugin_types", "prefetch_src", "report_to", "report_uri", "require_sri_for",
                        "sandbox", "script_src", "script_src_attr", "script_src_elem", "style_src", "style_src_attr",
                        "style_src_elem", "worker_src",
                      ] %}
  describe "\#{{ directive.id }}=" do
    it "allows to assign a string value" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = "value"

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["value"]
    end

    it "allows to assign a symbol value" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = :self

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["'self'"]
    end

    it "allows to assign an array of string values" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = ["foo", "bar"]

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["foo", "bar"]
    end

    it "allows to assign an array of symbol values" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = [:self, :unsafe_eval]

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["'self'", "'unsafe-eval'"]
    end

    it "allows to assign an array of symbol and string values" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = [:self, "bar"]

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["'self'", "bar"]
    end

    it "allows to assign a tuple of string values" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = {"foo", "bar"}

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["foo", "bar"]
    end

    it "allows to assign a tuple of symbol values" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = {:self, :unsafe_eval}

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["'self'", "'unsafe-eval'"]
    end

    it "allows to assign a tuple of symbol and string values" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = {:self, "bar"}

      csp.directives[{{ directive.gsub(/_/, "-") }}].should eq ["'self'", "bar"]
    end

    it "deletes the previously assigned value if the passed value is nil" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = nil

      csp.directives[{{ directive.gsub(/_/, "-") }}]?.should be_nil
    end
  end
  {% end %}

  {% for directive in ["block_all_mixed_content", "upgrade_insecure_requests"] %}
  describe "\#{{ directive.id }}=" do
    it "can enable the directive" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = true

      csp.directives[{{ directive.gsub(/_/, "-") }}].should be_true
    end

    it "can disable the directive if it was already present" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = true
      csp.{{ directive.id }} = false

      csp.directives[{{ directive.gsub(/_/, "-") }}]?.should be_nil
    end

    it "can disable the directive if it was not already present" do
      csp = Marten::HTTP::ContentSecurityPolicy.new

      csp.{{ directive.id }} = false

      csp.directives[{{ directive.gsub(/_/, "-") }}]?.should be_nil
    end
  end
  {% end %}

  describe "#build" do
    it "generates the expected header value when no nonce is used" do
      csp = Marten::HTTP::ContentSecurityPolicy.new
      csp.default_src = :self
      csp.font_src = [:self, "example.com"]

      csp.build.should eq "default-src 'self'; font-src 'self' example.com"
    end

    it "generates the expected header value specific boolean directives are enabled" do
      csp = Marten::HTTP::ContentSecurityPolicy.new
      csp.default_src = :self
      csp.font_src = [:self, "example.com"]
      csp.block_all_mixed_content = true

      csp.build.should eq "default-src 'self'; font-src 'self' example.com; block-all-mixed-content"
    end

    it "generates the expected header values when a nonce is used" do
      csp = Marten::HTTP::ContentSecurityPolicy.new
      csp.default_src = :self
      csp.font_src = [:self, "example.com"]
      csp.script_src = [:self, "example.com"]
      csp.script_src = :self

      csp.build(nonce: "testnonce", nonce_directives: ["script-src", "style-src"]).should eq(
        "default-src 'self'; font-src 'self' example.com; script-src 'self' 'nonce-testnonce'"
      )
    end

    it "defaults to using the nonce directives from the configuration if not specified" do
      with_overridden_setting(
        "content_security_policy.nonce_directives",
        ["script-src", "style-src"],
        nilable: true
      ) do
        csp = Marten::HTTP::ContentSecurityPolicy.new
        csp.default_src = :self
        csp.font_src = [:self, "example.com"]
        csp.script_src = [:self, "example.com"]
        csp.script_src = :self

        csp.build(nonce: "testnonce").should eq(
          "default-src 'self'; font-src 'self' example.com; script-src 'self' 'nonce-testnonce'"
        )
      end
    end
  end

  describe "#clone" do
    it "returns a clone of the Content-Security-Policy" do
      csp = Marten::HTTP::ContentSecurityPolicy.new
      csp.default_src = :self
      csp.font_src = [:self, "example.com"]
      csp.script_src = [:self, "example.com"]
      csp.script_src = :self

      cloned_csp = csp.clone

      cloned_csp.build(nonce: "testnonce").should eq(
        "default-src 'self'; font-src 'self' example.com; script-src 'self' 'nonce-testnonce'"
      )

      cloned_csp.object_id.should_not eq csp.object_id
      cloned_csp.directives.each do |k, v|
        next if v.is_a?(Bool)

        v.object_id.should_not eq csp.directives[k].as(Array).object_id
      end
    end
  end
end
