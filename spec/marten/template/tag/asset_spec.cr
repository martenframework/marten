require "./spec_helper"

describe Marten::Template::Tag::Asset do
  describe "::new" do
    it "raises if the url tag does not contain at least one argument" do
      parser = Marten::Template::Parser.new("{% asset %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed asset tag: at least one argument must be provided"
      ) do
        Marten::Template::Tag::Asset.new(parser, "asset")
      end
    end

    it "raises if the url tag contains more than one argument" do
      parser = Marten::Template::Parser.new("{% asset 'css/app.css' other args %}")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed asset tag: only one argument must be provided"
      ) do
        Marten::Template::Tag::Asset.new(parser, "asset 'css/app.css' other args")
      end
    end
  end

  describe "#render" do
    it "is able to returns the right URL for an asset defined as a literal value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Asset.new(parser, %{asset "css/app.css"})
      tag.render(Marten::Template::Context.new).should eq Marten.assets.storage.url("css/app.css")
    end

    it "is able to resolves asset names from the context" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Asset.new(parser, "asset aname")
      tag.render(Marten::Template::Context{"aname" => "css/app.css"}).should eq Marten.assets.storage.url("css/app.css")
    end

    it "is able to asign the resolved URL to a specific variable" do
      parser = Marten::Template::Parser.new("")

      tag = Marten::Template::Tag::Asset.new(parser, %{asset "css/app.css" as asset_url})
      context = Marten::Template::Context.new

      tag.render(context).should eq ""
      context["asset_url"].should eq Marten.assets.storage.url("css/app.css")
    end
  end
end
