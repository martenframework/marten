require "./spec_helper"

describe Marten::Template::Object do
  describe "#template_attributes" do
    it "allows to generate a #resolve_template_attribute method returning method return values" do
      test = Marten::Template::ObjectSpec::Test.new
      test.resolve_template_attribute("foo").should eq "foo"
      test.resolve_template_attribute("bar").should eq "bar"
      test.resolve_template_attribute("xyz").should be_nil
    end
  end
end

module Marten::Template::ObjectSpec
  class Test
    include Marten::Template::Object

    template_attributes :foo, "bar"

    def foo
      "foo"
    end

    def bar
      "bar"
    end

    def xyz
      "xyz"
    end
  end
end
