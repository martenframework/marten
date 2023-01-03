require "./spec_helper"

describe Marten::Template::Object::Auto do
  describe "#resolve_template_attribute" do
    it "allows to resolve a public method that does not take any argument" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      obj.resolve_template_attribute("attr").should eq "hello"
    end

    it "does not allow to resolve a method that takes arguments" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      obj.resolve_template_attribute("with_args").should be_nil
    end

    it "does not allow to resolve a method that takes a block" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      obj.resolve_template_attribute("with_block").should be_nil
    end

    it "does not allow to resolve a protected method" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      obj.resolve_template_attribute("protected_attr").should be_nil
    end

    it "does not allow to resolve a private method" do
      obj = Marten::Template::Object::AutoSpec::Test.new
      obj.resolve_template_attribute("private_attr").should be_nil
    end
  end
end

module Marten::Template::Object::AutoSpec
  class Test
    include Marten::Template::Object::Auto

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
