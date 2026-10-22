require "./spec_helper"

describe Marten::HTTP::Params::Query do
  describe "#resolve_template_attribute" do
    it "resolves a query value" do
      params = Marten::HTTP::Params::Query.new(
        Marten::HTTP::Params::Query::RawHash{"foo" => ["bar"], "xyz" => ["test1", "test2"]}
      )

      params.resolve_template_attribute("foo").should eq "bar"
      params.resolve_template_attribute("xyz").should eq "test2"
    end

    it "falls back to public methods and rejects unknown attributes" do
      params = Marten::HTTP::Params::Query.new

      params.resolve_template_attribute("size").should eq 0
      expect_raises(Marten::Template::Errors::UnknownVariable) do
        params.resolve_template_attribute("unknown")
      end
    end

    it "looks up query values before methods with the same name" do
      params = Marten::HTTP::Params::Query.new({"size" => ["large"]})

      params.resolve_template_attribute("size").should eq "large"
    end
  end

  it "renders missing request query values as empty strings" do
    request = Marten::HTTP::Request.new(HTTP::Request.new("GET", "/"))
    template = Marten::Template::Template.new("{{ request.query_params.email_address }}")

    with_overridden_setting("templates.strict_variables", false) do
      template.render({"request" => request}).should eq ""
    end
  end

  it "renders and escapes request query values across garbage collections" do
    request = Marten::HTTP::Request.new(HTTP::Request.new("GET", "/?email_address=%3Cbea%40example.com%3E"))
    template = Marten::Template::Template.new("{{ request.query_params.email_address }}")

    100.times do
      template.render({"request" => request}).should eq "&lt;bea@example.com&gt;"
      GC.collect
    end
  end
end
