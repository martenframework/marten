require "./spec_helper"

describe Marten::Template::Context do
  after_each do
    Marten.setup_templates
  end

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

    it "applies the configured context producers as expected" do
      with_overridden_setting(
        "templates.context_producers",
        [Marten::Template::ContextSpec::StaticContextProducer, Marten::Template::ContextSpec::RequestContextProducer]
      ) do
        Marten.setup_templates

        ctx = Marten::Template::Context.from({"foo" => "bar"})

        ctx["foo"].should eq "bar"
        ctx["static_context_producer"].should eq "applied"
        expect_raises(KeyError) { ctx["request"] }
      end
    end

    context "with a request" do
      it "can be used to initialize a context from a given hash" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        ctx = Marten::Template::Context.from({"foo" => "bar"}, request)

        ctx.empty?.should be_false
        ctx["foo"].should eq "bar"
      end

      it "can be used to initialize a context from a given named tuple" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        ctx = Marten::Template::Context.from({foo: "bar"}, request)

        ctx.empty?.should be_false
        ctx["foo"].should eq "bar"
      end

      it "can be used to initialize a context from a nil value" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        ctx = Marten::Template::Context.from(nil, request)

        ctx.empty?.should be_true
      end

      it "returns any existing context object it receives as argument" do
        request = Marten::HTTP::Request.new(
          ::HTTP::Request.new(
            method: "GET",
            resource: "",
            headers: HTTP::Headers{"Host" => "example.com"}
          )
        )

        ctx1 = Marten::Template::Context.from({"foo" => "bar"}, request)
        ctx2 = Marten::Template::Context.from(ctx1, request)

        ctx2.should be ctx1
      end

      it "applies the configured context producers as expected" do
        with_overridden_setting(
          "templates.context_producers",
          [Marten::Template::ContextSpec::StaticContextProducer, Marten::Template::ContextSpec::RequestContextProducer]
        ) do
          Marten.setup_templates

          request = Marten::HTTP::Request.new(
            ::HTTP::Request.new(
              method: "GET",
              resource: "",
              headers: HTTP::Headers{"Host" => "example.com"}
            )
          )

          ctx = Marten::Template::Context.from({"foo" => "bar"}, request)

          ctx["foo"].should eq "bar"
          ctx["static_context_producer"].should eq "applied"
          ctx["request"].should eq request
        end
      end
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

    it "returns the value corresponding to the passed key symbol" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx[:foo].should eq "bar"
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

    it "returns the value corresponding to the passed key" do
      ctx = Marten::Template::Context{"foo" => "bar"}
      ctx[:foo]?.should eq "bar"
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

    it "allows to insert a specific template value for a given key symbol into the context" do
      value = Marten::Template::Value.from("bar")
      ctx = Marten::Template::Context.new
      ctx[:foo] = value
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

  describe "#merge" do
    it "merges another context object into the current one" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}
      other_context = Marten::Template::Context{"xyz" => "test", "foo" => "updated"}

      context.merge(other_context).should eq context

      context["foo"].should eq "updated"
      context["john"].should eq "doe"
      context["xyz"].should eq "test"
    end

    it "merges a hash into the current context" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}
      other_context = {"xyz" => "test", "foo" => "updated"}

      context.merge(other_context).should eq context

      context["foo"].should eq "updated"
      context["john"].should eq "doe"
      context["xyz"].should eq "test"
    end

    it "merges a named tuple into the current context" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}
      other_context = {xyz: "test", foo: "updated"}

      context.merge(other_context).should eq context

      context["foo"].should eq "updated"
      context["john"].should eq "doe"
      context["xyz"].should eq "test"
    end

    it "merges another context object on the last stack only" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}
      other_context = Marten::Template::Context{"xyz" => "test", "foo" => "updated"}

      context.stack do |stacked_context|
        stacked_context.merge(other_context).should eq stacked_context

        stacked_context["foo"].should eq "updated"
        stacked_context["john"].should eq "doe"
        stacked_context["xyz"].should eq "test"
      end

      context["foo"].should eq "bar"
      context["john"].should eq "doe"
      context["xyz"]?.should be_nil
    end

    it "merges another hash on the last stack only" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}
      other_context = {"xyz" => "test", "foo" => "updated"}

      context.stack do |stacked_context|
        stacked_context.merge(other_context).should eq stacked_context

        stacked_context["foo"].should eq "updated"
        stacked_context["john"].should eq "doe"
        stacked_context["xyz"].should eq "test"
      end

      context["foo"].should eq "bar"
      context["john"].should eq "doe"
      context["xyz"]?.should be_nil
    end

    it "merges another named tuple on the last stack only" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}
      other_context = {xyz: "test", foo: "updated"}

      context.stack do |stacked_context|
        stacked_context.merge(other_context).should eq stacked_context

        stacked_context["foo"].should eq "updated"
        stacked_context["john"].should eq "doe"
        stacked_context["xyz"].should eq "test"
      end

      context["foo"].should eq "bar"
      context["john"].should eq "doe"
      context["xyz"]?.should be_nil
    end

    it "merges by following the order of stacks of the other context" do
      context = Marten::Template::Context{"foo" => "bar", "john" => "doe"}

      other_context = Marten::Template::Context{"xyz" => "test", "foo" => "updated"}
      other_context.stack do |other_stacked_context|
        other_stacked_context["foo"] = "updated_2"
        other_stacked_context["john"] = "doe_2"

        context.merge(other_context).should eq context
      end

      context["foo"].should eq "updated_2"
      context["john"].should eq "doe_2"
      context["xyz"].should eq "test"
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

    it "returns the underlying block value" do
      ctx = Marten::Template::Context{"foo" => "bar"}

      result = ctx.stack do |depth_1_ctx|
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

        42
      end

      ctx["foo"].should eq "bar"
      ctx["depth_1_foo"]?.should be_nil
      ctx["depth_2_foo"]?.should be_nil

      result.should eq 42
    end
  end
end

module Marten::Template::ContextSpec
  class StaticContextProducer < Marten::Template::ContextProducer
    def produce(request : HTTP::Request? = nil)
      {"static_context_producer" => "applied"}
    end
  end

  class RequestContextProducer < Marten::Template::ContextProducer
    def produce(request : HTTP::Request? = nil)
      return if request.nil?

      {"request" => request}
    end
  end
end
