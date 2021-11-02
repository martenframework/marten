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

    it "can be used to initialize a context from a nil value" do
      ctx = Marten::Template::Context.from(nil)
      ctx.empty?.should be_true
    end

    it "returns any existing context object it receives as argument" do
      ctx1 = Marten::Template::Context.from({"foo" => "bar"})
      ctx2 = Marten::Template::Context.from(ctx1)
      ctx2.should be ctx1
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

    it "returns the value corresponding to most recent values stack" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx.stack do |depth_1_ctx|
        depth_1_ctx["foo"].should eq "bar"

        depth_1_ctx["foo"] = "depth_1_bar"
        depth_1_ctx["foo"].should eq "depth_1_bar"

        ctx.stack do |depth_2_ctx|
          depth_2_ctx["foo"].should eq "depth_1_bar"

          depth_2_ctx["foo"] = "depth_2_bar"
          depth_2_ctx["foo"].should eq "depth_2_bar"
        end

        depth_1_ctx["foo"].should eq "depth_1_bar"
      end

      ctx["foo"].should eq "bar"
    end

    it "raises a KeyError exception if no value corresponds to the passed key" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      expect_raises(KeyError) { ctx["xyz"] }
    end
  end

  describe "#[]?" do
    it "returns the value corresponding to the passed key" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx["foo"]?.should eq "bar"
    end

    it "returns the value corresponding to most recent values stack" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx.stack do |depth_1_ctx|
        depth_1_ctx["foo"]?.should eq "bar"

        depth_1_ctx["foo"] = "depth_1_bar"
        depth_1_ctx["foo"]?.should eq "depth_1_bar"

        ctx.stack do |depth_2_ctx|
          depth_2_ctx["foo"]?.should eq "depth_1_bar"

          depth_2_ctx["foo"] = "depth_2_bar"
          depth_2_ctx["foo"]?.should eq "depth_2_bar"
        end

        depth_1_ctx["foo"]?.should eq "depth_1_bar"
      end

      ctx["foo"]?.should eq "bar"
    end

    it "returns nil if no value corresponds to the passed key" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx["xyz"]?.should be_nil
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

    it "is consistent with values stacks" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx.stack do |depth_1_ctx|
        depth_1_ctx["foo"].should eq "bar"

        depth_1_ctx["depth_1_foo"] = "depth_1_bar"
        depth_1_ctx["depth_1_foo"].should eq "depth_1_bar"

        ctx.stack do |depth_2_ctx|
          depth_2_ctx["foo"].should eq "bar"
          depth_2_ctx["depth_1_foo"].should eq "depth_1_bar"

          depth_2_ctx["depth_2_foo"] = "depth_2_bar"
          depth_2_ctx["depth_2_foo"].should eq "depth_2_bar"
        end

        depth_1_ctx["foo"].should eq "bar"
        depth_1_ctx["depth_1_foo"].should eq "depth_1_bar"
      end

      ctx["foo"].should eq "bar"
      ctx["depth_1_foo"]?.should be_nil
      ctx["depth_2_foo"]?.should be_nil
    end
  end

  describe "#stack" do
    it "adds another stack of values to the context" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx.stack do |depth_1_ctx|
        depth_1_ctx["foo"].should eq "bar"

        depth_1_ctx["depth_1_foo"] = "depth_1_bar"
        depth_1_ctx["depth_1_foo"].should eq "depth_1_bar"

        ctx.stack do |depth_2_ctx|
          depth_2_ctx["foo"].should eq "bar"
          depth_2_ctx["depth_1_foo"].should eq "depth_1_bar"

          depth_2_ctx["depth_2_foo"] = "depth_2_bar"
          depth_2_ctx["depth_2_foo"].should eq "depth_2_bar"
        end

        depth_1_ctx["foo"].should eq "bar"
        depth_1_ctx["depth_1_foo"].should eq "depth_1_bar"
      end

      ctx["foo"].should eq "bar"
      ctx["depth_1_foo"]?.should be_nil
      ctx["depth_2_foo"]?.should be_nil
    end

    it "can be used to override values consistently" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx.stack do |depth_1_ctx|
        depth_1_ctx["foo"].should eq "bar"

        depth_1_ctx["foo"] = "depth_1_bar"
        depth_1_ctx["foo"].should eq "depth_1_bar"

        ctx.stack do |depth_2_ctx|
          depth_2_ctx["foo"].should eq "depth_1_bar"

          depth_2_ctx["foo"] = "depth_2_bar"
          depth_2_ctx["foo"].should eq "depth_2_bar"
        end

        depth_1_ctx["foo"].should eq "depth_1_bar"
      end

      ctx["foo"].should eq "bar"
    end

    it "removes the stacked layer of values if an error occurs" do
      ctx = Marten::Template::Context{"foo" => "bar"}

      expect_raises(Exception) do
        ctx.stack do |inner_ctx|
          inner_ctx["foo"] = "inner_bar"
          inner_ctx["test"] = 42
          raise "BAD"
        end
      end

      ctx["foo"].should eq "bar"
      ctx["test"]?.should be_nil
    end
  end
end
