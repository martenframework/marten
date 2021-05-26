require "./spec_helper"

describe Marten::Template::Tag::Translate do
  describe "::new" do
    it "raises if the translate tag does not contain at least one argument" do
      parser = Marten::Template::Parser.new("")

      expect_raises(
        Marten::Template::Errors::InvalidSyntax,
        "Malformed translate tag: at least one argument must be provided"
      ) do
        Marten::Template::Tag::Translate.new(parser, "translate")
      end
    end
  end

  describe "#render" do
    it "is able to perform a simple translation lookup" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Translate.new(parser, %{translate "simple.translation"})
      tag.render(Marten::Template::Context.new).should eq I18n.t("simple.translation")
    end

    it "is able to perform a translation lookup involving interpolations" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Translate.new(parser, %{translate "simple.interpolation" name: "John Doe"})
      tag.render(Marten::Template::Context.new).should eq I18n.t("simple.interpolation", name: "John Doe")
    end

    it "is able to perform a translation lookup involving a pluralization" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Translate.new(parser, %{translate "simple.pluralization" count: 1})
      tag_1.render(Marten::Template::Context.new).should eq I18n.t("simple.pluralization", count: 1)

      tag_2 = Marten::Template::Tag::Translate.new(parser, %{translate "simple.pluralization" count: 42})
      tag_2.render(Marten::Template::Context.new).should eq I18n.t("simple.pluralization", count: 42)

      tag_3 = Marten::Template::Tag::Translate.new(parser, %{translate "simple.pluralization" count: 42.44})
      tag_3.render(Marten::Template::Context.new).should eq I18n.t("simple.pluralization", count: 42.44)
    end

    it "is able to resolve translation keys from the context" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Translate.new(parser, %{translate txkey})
      tag_1.render(Marten::Template::Context{"txkey" => "simple.translation"}).should eq I18n.t("simple.translation")

      tag_2 = Marten::Template::Tag::Translate.new(parser, %{translate txkey name: 'John'})
      tag_2.render(Marten::Template::Context{"txkey" => "simple.interpolation"}).should eq(
        I18n.t("simple.interpolation", name: "John")
      )
    end

    it "is able to resolve translation parameters from the context" do
      parser = Marten::Template::Parser.new("")

      tag_1 = Marten::Template::Tag::Translate.new(parser, %{translate "simple.interpolation" name: cname})
      tag_1.render(Marten::Template::Context{"cname" => "John Doe"}).should eq(
        I18n.t("simple.interpolation", name: "John Doe")
      )

      tag_2 = Marten::Template::Tag::Translate.new(parser, %{translate "simple.pluralization" count: number})
      tag_2.render(Marten::Template::Context{"number" => 42}).should eq I18n.t("simple.pluralization", count: 42)
    end

    it "is able to asign the resolved translatin to a specific variable" do
      parser = Marten::Template::Parser.new("")

      context = Marten::Template::Context{"cname" => "John Doe"}
      tag = Marten::Template::Tag::Translate.new(parser, %{translate "simple.interpolation" name: cname as resolved})
      tag.render(context).should eq ""
      context["resolved"].should eq I18n.t("simple.interpolation", name: "John Doe")
    end

    it "raises if one of the count parameter id not a number or a nil value" do
      parser = Marten::Template::Parser.new("")
      tag = Marten::Template::Tag::Translate.new(parser, %{translate "simple.pluralization" count: number})

      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Hash(Marten::Template::Value, Marten::Template::Value) objects cannot be used for translation count parameters"
      ) do
        tag.render(Marten::Template::Context{"number" => {"foo" => "bar"}})
      end
    end
  end
end
