require "./spec_helper"

describe Marten::Template::Context do
  describe "::from" do
    it "can be used to initialize a context from a given hash" do
      ctx = Marten::Template::Context.from({"foo" => "bar"})
      ctx.empty?.should be_false
      ctx["foo"].should eq "bar"
    end

    it "can be used to initialize a context from a given named tuple" do
      ctx = Marten::Template::Context.from({foo: "bar"})
      ctx.empty?.should be_false
      ctx["foo"].should eq "bar"
    end
  end

  describe "::new" do
    it "can be used to initialize an empty context" do
      ctx = Marten::Template::Context.new
      ctx.empty?.should be_true
    end

    it "can be used to initialize a context from a specific hash of template values" do
      ctx = Marten::Template::Context.new({"foo" => Marten::Template::Value.from("bar")})
      ctx.empty?.should be_false
      ctx["foo"].should eq "bar"
    end
  end

  describe "#[]" do
    it "returns the value corresponding to the passed key" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx["foo"].should eq "bar"
    end

    it "raises a KeyError exception if no value corresponds to the passed key" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      expect_raises(KeyError) { ctx["xyz"] }
    end
  end

  describe "#[]=" do
    it "allows to insert a specific template value for a given key into the context" do
      value = Marten::Template::Value.from("bar")
      ctx = Marten::Template::Context.new
      ctx["foo"] = value
      ctx["foo"].should eq value
    end

    it "allows to insert a non-template value for a given key into the context" do
      ctx = Marten::Template::Context.new
      ctx["foo"] = "bar"
      ctx["foo"].should eq Marten::Template::Value.from("bar")
    end
  end
end
