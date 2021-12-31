require "./spec_helper"

describe Marten::DB::Model::Callbacks do
  describe "::before_create" do
    it "allows to register a single before_create callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleBeforeCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("before_create")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_create callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_create")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_create callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_create")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::before_update" do
    it "allows to register a single before_update callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleBeforeCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("before_update")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_update callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_update")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_update callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_update")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::before_save" do
    it "allows to register a single before_save callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleBeforeCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("before_save")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_save callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_save")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_save callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_save")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::before_delete" do
    it "allows to register a single before_delete callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleBeforeCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("before_delete")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_delete callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_delete")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_delete callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleBeforeCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("before_delete")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_initialize" do
    it "allows to register a single after_initialize callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_initialize")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_initialize callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_initialize")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_initialize callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_initialize")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_create" do
    it "allows to register a single after_create callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_create")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_create callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_create")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_create callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_create")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_update" do
    it "allows to register a single after_update callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_update")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_update callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_update")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_update callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_update")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_save" do
    it "allows to register a single after_save callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_save")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_save callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_save")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_save callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_save")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_delete" do
    it "allows to register a single after_delete callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_delete")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_delete callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_delete")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_delete callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_delete")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "#run_before_create_callbacks" do
    it "runs the before_create callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks("before_create")

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks("before_create")

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_before_update_callbacks" do
    it "runs the before_update callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks("before_update")

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks("before_update")

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_before_save_callbacks" do
    it "runs the before_save callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks("before_save")

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks("before_save")

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_before_delete_callbacks" do
    it "runs the before_delete callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks("before_delete")

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks("before_delete")

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_after_initialize_callbacks" do
    it "runs the after_initialize callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_initialize")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_initialize")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_create_callbacks" do
    it "runs the after_create callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_create")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_create")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_update_callbacks" do
    it "runs the after_update callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_update")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_update")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_save_callbacks" do
    it "runs the after_save callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_save")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_save")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_delete_callbacks" do
    it "runs the after_delete callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_delete")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_delete")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end
end

module Marten::DB::Model::CallbacksSpec
  class Base
    include Marten::DB::Model::Callbacks

    def run_callbacks(callback = nil)
      run_after_initialize_callbacks if callback.nil? || callback == "after_initialize"
      run_before_create_callbacks if callback.nil? || callback == "before_create"
      run_after_create_callbacks if callback.nil? || callback == "after_create"
      run_before_update_callbacks if callback.nil? || callback == "before_update"
      run_after_update_callbacks if callback.nil? || callback == "after_update"
      run_before_save_callbacks if callback.nil? || callback == "before_save"
      run_after_save_callbacks if callback.nil? || callback == "after_save"
      run_before_delete_callbacks if callback.nil? || callback == "before_delete"
      run_after_delete_callbacks if callback.nil? || callback == "after_delete"
    end
  end

  class SingleBeforeCallback < Base
    property foo : String? = nil

    before_create :set_foo
    before_update :set_foo
    before_save :set_foo
    before_delete :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleBeforeCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_create :set_foo, :set_bar
    before_update :set_foo, :set_bar
    before_save :set_foo, :set_bar
    before_delete :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleBeforeCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_create :set_foo
    before_create "set_bar"
    before_update :set_foo
    before_update "set_bar"
    before_save :set_foo
    before_save "set_bar"
    before_delete :set_foo
    before_delete "set_bar"

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterCallback < Base
    property foo : String? = nil

    after_initialize :set_foo
    after_create :set_foo
    after_update :set_foo
    after_save :set_foo
    after_delete :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    after_initialize :set_foo, :set_bar
    after_create :set_foo, :set_bar
    after_update :set_foo, :set_bar
    after_save :set_foo, :set_bar
    after_delete :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleAfterCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    after_initialize :set_foo
    after_initialize :set_bar
    after_create :set_foo
    after_create :set_bar
    after_update :set_foo
    after_update :set_bar
    after_save :set_foo
    after_save :set_bar
    after_delete :set_foo
    after_delete :set_bar

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

    property foo_after : String? = nil
    property shared_after : String? = nil

    before_create :set_one_before
    before_create :set_two_before
    before_create :set_foo_before

    before_update :set_one_before
    before_update :set_two_before
    before_update :set_foo_before

    before_save :set_one_before
    before_save :set_two_before
    before_save :set_foo_before

    before_delete :set_one_before
    before_delete :set_two_before
    before_delete :set_foo_before

    after_initialize :set_one_after
    after_initialize :set_two_after
    after_initialize :set_foo_after

    after_create :set_one_after
    after_create :set_two_after
    after_create :set_foo_after

    after_update :set_one_after
    after_update :set_two_after
    after_update :set_foo_after

    after_save :set_one_after
    after_save :set_two_after
    after_save :set_foo_after

    after_delete :set_one_after
    after_delete :set_two_after
    after_delete :set_foo_after

    private def set_one_before
      self.shared_before = "one"
    end

    private def set_two_before
      self.shared_before = "two"
    end

    private def set_foo_before
      self.foo_before = "set_foo"
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

    property abc_after : String? = nil

    before_create :set_three_before
    before_create :set_abc_before

    before_update :set_three_before
    before_update :set_abc_before

    before_save :set_three_before
    before_save :set_abc_before

    before_delete :set_three_before
    before_delete :set_abc_before

    after_initialize :set_three_after
    after_initialize :set_abc_after

    after_create :set_three_after
    after_create :set_abc_after

    after_update :set_three_after
    after_update :set_abc_after

    after_save :set_three_after
    after_save :set_abc_after

    after_delete :set_three_after
    after_delete :set_abc_after

    private def set_three_before
      self.shared_before = "three"
    end

    private def set_abc_before
      self.abc_before = "set_abc"
    end

    private def set_three_after
      self.shared_after = "three"
    end

    private def set_abc_after
      self.abc_after = "set_abc"
    end
  end
end
