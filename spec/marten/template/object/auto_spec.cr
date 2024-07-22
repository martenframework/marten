require "./spec_helper"

describe Marten::Template::Object::Auto do
  describe "#resolve_template_attribute" do
    it "allows to resolve a public method that does not take any argument" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      obj.resolve_template_attribute("attr").should eq "hello"
    end

    it "allows to resolve a key using the #[] method as a fallback" do
      obj = Marten::Template::Object::AutoSpec::Test.new({"foo" => "bar"})
      obj.resolve_template_attribute("foo").should eq "bar"
    end

    it "resolves values #[] with priority over a method with the same key" do
      obj = Marten::Template::Object::AutoSpec::Test.new({"attr" => "bar"})
      obj.resolve_template_attribute("attr").should eq "bar"
    end

    it "does not allow to resolve a method that takes arguments" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      expect_raises(Marten::Template::Errors::UnknownVariable) do
        obj.resolve_template_attribute("with_args")
      end
    end

    it "does not allow to resolve a method that takes a block" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      expect_raises(Marten::Template::Errors::UnknownVariable) do
        obj.resolve_template_attribute("with_block")
      end
    end

    it "does not allow to resolve a protected method" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      expect_raises(Marten::Template::Errors::UnknownVariable) do
        obj.resolve_template_attribute("protected_attr")
      end
    end

    it "does not allow to resolve a private method" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      expect_raises(Marten::Template::Errors::UnknownVariable) do
        obj.resolve_template_attribute("private_attr")
      end
    end

    it "raises a Marten::Template::Errors::UnknownVariable exception if the attribute is not supported" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      expect_raises(Marten::Template::Errors::UnknownVariable) do
        obj.resolve_template_attribute("unknown")
      end
    end
  end
end

module Marten::Template::Object::AutoSpec
  class Test
    include Marten::Template::Object::Auto

    def initialize(@data = {} of String => String)
    end

    def [](key : String)
      @data[key]
    end

    def attr
      "hello"
    end

    def with_args(arg : String)
      "hello"
    end

    def with_block(&)
      yield
    end

    protected def protected_attr
      "hello"
    end

    private def private_attr
      "hello"
    end
  end
end
