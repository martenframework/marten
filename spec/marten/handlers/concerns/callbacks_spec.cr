require "./spec_helper"

describe Marten::Handlers::Callbacks do
  describe "::before_dispatch" do
    it "allows to register a single before_dispatch callback" do
      obj = Marten::Handlers::CallbacksSpec::SingleBeforeDispatchCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_dispatch callbacks through a single call" do
      obj = Marten::Handlers::CallbacksSpec::MultipleBeforeDispatchCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_dispatch callbacks through multiple calls" do
      obj = Marten::Handlers::CallbacksSpec::MultipleBeforeDispatchCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::before_render" do
    it "allows to register a single before_render callback" do
      obj = Marten::Handlers::CallbacksSpec::SingleBeforeRenderCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_render callbacks through a single call" do
      obj = Marten::Handlers::CallbacksSpec::MultipleBeforeRenderCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_render callbacks through multiple calls" do
      obj = Marten::Handlers::CallbacksSpec::MultipleBeforeRenderCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_dispatch" do
    it "allows to register a single after_dispatch callback" do
      obj = Marten::Handlers::CallbacksSpec::SingleAfterDispatchCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_dispatch callbacks through a single call" do
      obj = Marten::Handlers::CallbacksSpec::MultipleAfterDispatchCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_dispatch callbacks through multiple calls" do
      obj = Marten::Handlers::CallbacksSpec::MultipleAfterDispatchCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "#run_before_dispatch_callbacks" do
    it "runs the before_dispatch callbacks in the order they were registered" do
      obj = Marten::Handlers::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_before_render_callbacks" do
    it "runs the before_render callbacks in the order they were registered" do
      obj = Marten::Handlers::CallbacksSpec::Parent.new

      obj.shared_before_render.should be_nil

      obj.run_callbacks

      obj.shared_before_render.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::CallbacksSpec::Child.new

      obj.shared_before_render.should be_nil
      obj.foo_before_render.should be_nil
      obj.abc_before_render.should be_nil

      obj.run_callbacks

      obj.shared_before_render.should eq "three"
      obj.foo_before_render.should eq "set_foo"
      obj.abc_before_render.should eq "set_abc"
    end
  end

  describe "#run_after_dispatch_callbacks" do
    it "runs the after_dispatch callbacks in the order they were registered" do
      obj = Marten::Handlers::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end
end

module Marten::Handlers::CallbacksSpec
  class Base
    include Marten::Handlers::Callbacks

    def run_callbacks
      run_before_dispatch_callbacks
      run_before_render_callbacks
      run_after_dispatch_callbacks
    end
  end

  class SingleBeforeDispatchCallback < Base
    property foo : String? = nil

    before_dispatch :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleBeforeDispatchCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_dispatch :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleBeforeDispatchCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_dispatch :set_foo
    before_dispatch :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleBeforeRenderCallback < Base
    property foo : String? = nil

    before_render :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleBeforeRenderCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_render :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleBeforeRenderCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_render :set_foo
    before_render :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterDispatchCallback < Base
    property foo : String? = nil

    after_dispatch :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterDispatchCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    after_dispatch :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleAfterDispatchCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    after_dispatch :set_foo
    after_dispatch :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class Parent < Base
    property foo_before : String? = nil
    property shared_before : String? = nil

    property foo_before_render : String? = nil
    property shared_before_render : String? = nil

    property foo_after : String? = nil
    property shared_after : String? = nil

    before_dispatch :set_one_before
    before_dispatch :set_two_before
    before_dispatch :set_foo_before

    before_render :set_one_before_render
    before_render :set_two_before_render
    before_render :set_foo_before_render

    after_dispatch :set_one_after
    after_dispatch :set_two_after
    after_dispatch :set_foo_after

    private def set_one_before
      self.shared_before = "one"
    end

    private def set_two_before
      self.shared_before = "two"
    end

    private def set_foo_before
      self.foo_before = "set_foo"
    end

    private def set_one_before_render
      self.shared_before_render = "one"
    end

    private def set_two_before_render
      self.shared_before_render = "two"
    end

    private def set_foo_before_render
      self.foo_before_render = "set_foo"
    end

    private def set_one_after
      self.shared_after = "one"
    end

    private def set_two_after
      self.shared_after = "two"
    end

    private def set_foo_after
      self.foo_after = "set_foo"
    end
  end

  class Child < Parent
    property abc_before : String? = nil

    property abc_before_render : String? = nil

    property abc_after : String? = nil

    before_dispatch :set_three_before
    before_dispatch :set_abc_before

    before_render :set_three_before_render
    before_render :set_abc_before_render

    after_dispatch :set_three_after
    after_dispatch :set_abc_after

    private def set_three_before
      self.shared_before = "three"
    end

    private def set_abc_before
      self.abc_before = "set_abc"
    end

    private def set_three_before_render
      self.shared_before_render = "three"
    end

    private def set_abc_before_render
      self.abc_before_render = "set_abc"
    end

    private def set_three_after
      self.shared_after = "three"
    end

    private def set_abc_after
      self.abc_after = "set_abc"
    end
  end
end
