require "./spec_helper"

module Marten::Routing::ParameterSpec
  describe Marten::Routing::Parameter do
    describe "::register" do
      it "allows to register a new path parameter implementation" do
        Marten::Routing::Parameter.register("foo", FooParameter)
        Marten::Routing::Parameter.registry["foo"].should be_a FooParameter
        Marten::Routing::Parameter.registry.delete("foo")
      end

      it "allows to register a new path parameter implementation using a symbol identifier" do
        Marten::Routing::Parameter.register(:foo, FooParameter)
        Marten::Routing::Parameter.registry["foo"].should be_a FooParameter
        Marten::Routing::Parameter.registry.delete("foo")
      end
    end

    describe "::registry" do
      it "returns the registered path parameter implementations" do
        Marten::Routing::Parameter.registry.size.should eq 4
        Marten::Routing::Parameter.registry["str"].should be_a Marten::Routing::Parameter::String
        Marten::Routing::Parameter.registry["int"].should be_a Marten::Routing::Parameter::Integer
        Marten::Routing::Parameter.registry["slug"].should be_a Marten::Routing::Parameter::Slug
        Marten::Routing::Parameter.registry["uuid"].should be_a Marten::Routing::Parameter::UUID
      end
    end
  end

  class FooParameter < Marten::Routing::Parameter::Base
    def regex : Regex
      /.+/
    end

    def loads(value : String) : String
      value
    end

    def dumps(value : String) : String
      value
    end
  end
end
