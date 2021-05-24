require "./spec_helper"

describe Marten::Template::Tag do
  describe "::get" do
    it "returns the right built-in tag classes for the expected tag names" do
      Marten::Template::Tag.get("for").should eq Marten::Template::Tag::For
      Marten::Template::Tag.get("if").should eq Marten::Template::Tag::If
      Marten::Template::Tag.get("spaceless").should eq Marten::Template::Tag::Spaceless
      Marten::Template::Tag.get("url").should eq Marten::Template::Tag::Url
    end

    it "returns a registered tag class for a given name string" do
      Marten::Template::Tag.get("spaceless").should eq Marten::Template::Tag::Spaceless
    end

    it "returns a registered tag class for a given name symbol" do
      Marten::Template::Tag.get(:spaceless).should eq Marten::Template::Tag::Spaceless
    end

    it "raises an InvalidSyntax error if no tag class is registered for the given name" do
      expect_raises(Marten::Template::Errors::InvalidSyntax, "Unknown tag with name 'unknown'") do
        Marten::Template::Tag.get("unknown")
      end
    end
  end

  describe "::register" do
    it "allows to register a tag class from a name string" do
      Marten::Template::Tag.register("__spec_test__", Marten::Template::TagSpec::Test)
      Marten::Template::Tag.get("__spec_test__").should eq Marten::Template::TagSpec::Test
    end

    it "allows to register a tag class from a name symbol" do
      Marten::Template::Tag.register(:__spec_test__, Marten::Template::TagSpec::Test)
      Marten::Template::Tag.get(:__spec_test__).should eq Marten::Template::TagSpec::Test
    end
  end
end

module Marten::Template::TagSpec
  class Test < Marten::Template::Tag::Base
    def render(context : Marten::Template::Context) : String
      ""
    end
  end
end
