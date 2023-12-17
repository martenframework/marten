require "./spec_helper"

describe Marten::Handlers::Schema::Callbacks do
  describe "::before_validate" do
    it "allows to register a single before_validate callback" do
      obj = Marten::Handlers::Schema::CallbacksSpec::SingleBeforeValidateCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple before_validate callbacks through a single call" do
      obj = Marten::Handlers::Schema::CallbacksSpec::MultipleBeforeValidateCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple before_validate callbacks through multiple calls" do
      obj = Marten::Handlers::Schema::CallbacksSpec::MultipleBeforeValidateCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_validate" do
    it "allows to register a single after_validate callback" do
      obj = Marten::Handlers::Schema::CallbacksSpec::SingleAfterValidateCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_validate callbacks through a single call" do
      obj = Marten::Handlers::Schema::CallbacksSpec::MultipleAfterValidateCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_validate callbacks through multiple calls" do
      obj = Marten::Handlers::Schema::CallbacksSpec::MultipleAfterValidateCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_successful_validate" do
    it "allows to register a single after_successful_validate callback" do
      obj = Marten::Handlers::Schema::CallbacksSpec::SingleAfterSuccessfulValidateCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_successful_validate callbacks through a single call" do
      obj =
        Marten::Handlers::Schema::CallbacksSpec::MultipleAfterSuccessfulValidateCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_successful_validate callbacks through multiple calls" do
      obj =
        Marten::Handlers::Schema::CallbacksSpec::MultipleAfterSuccessfulValidateCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_failed_validate" do
    it "allows to register a single after_failed_validate callback" do
      obj = Marten::Handlers::Schema::CallbacksSpec::SingleAfterFailedValidateCallback.new

      obj.foo.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_failed_validate callbacks through a single call" do
      obj = Marten::Handlers::Schema::CallbacksSpec::MultipleAfterFailedValidateCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_failed_validate callbacks through multiple calls" do
      obj = Marten::Handlers::Schema::CallbacksSpec::MultipleAfterFailedValidateCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "#run_before_validate_callbacks" do
    it "runs the before_validate callbacks in the order they were registered" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Parent.new

      obj.shared_before.should be_nil

      obj.run_callbacks

      obj.shared_before.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Child.new

      obj.shared_before.should be_nil
      obj.foo_before.should be_nil
      obj.abc_before.should be_nil

      obj.run_callbacks

      obj.shared_before.should eq "three"
      obj.foo_before.should eq "set_foo"
      obj.abc_before.should eq "set_abc"
    end
  end

  describe "#run_after_validate_callbacks" do
    it "runs the after_validate callbacks in the order they were registered" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_successful_validate_callbacks" do
    it "runs the after_successful_validate callbacks in the order they were registered" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Parent.new

      obj.shared_after_successful.should be_nil

      obj.run_callbacks

      obj.shared_after_successful.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Child.new

      obj.shared_after_successful.should be_nil
      obj.foo_after_successful.should be_nil
      obj.abc_after_successful.should be_nil

      obj.run_callbacks

      obj.shared_after_successful.should eq "three"
      obj.foo_after_successful.should eq "set_foo"
      obj.abc_after_successful.should eq "set_abc"
    end
  end

  describe "#run_after_failed_validate_callbacks" do
    it "runs the after_failed_validate callbacks in the order they were registered" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Parent.new

      obj.shared_after_failed.should be_nil

      obj.run_callbacks

      obj.shared_after_failed.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::Handlers::Schema::CallbacksSpec::Child.new

      obj.shared_after_failed.should be_nil
      obj.foo_after_failed.should be_nil
      obj.abc_after_failed.should be_nil

      obj.run_callbacks

      obj.shared_after_failed.should eq "three"
      obj.foo_after_failed.should eq "set_foo"
      obj.abc_after_failed.should eq "set_abc"
    end
  end
end

module Marten::Handlers::Schema::CallbacksSpec
  class Base
    include Marten::Handlers::Schema::Callbacks

    def run_callbacks
      run_before_validation_callbacks
      run_after_validation_callbacks
      run_after_successful_validation_callbacks
      run_after_failed_validation_callbacks
    end
  end

  class SingleBeforeValidateCallback < Base
    property foo : String? = nil

    before_schema_validation :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleBeforeValidateCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_schema_validation :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleBeforeValidateCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_schema_validation :set_foo
    before_schema_validation :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterValidateCallback < Base
    property foo : String? = nil

    after_schema_validation :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterValidateCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    after_schema_validation :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleAfterValidateCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    after_schema_validation :set_foo
    after_schema_validation :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterFailedValidateCallback < Base
    property foo : String? = nil

    before_schema_validation :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterFailedValidateCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_schema_validation :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleAfterFailedValidateCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_schema_validation :set_foo
    before_schema_validation :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterSuccessfulValidateCallback < Base
    property foo : String? = nil

    before_schema_validation :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterSuccessfulValidateCallbacksRegisteredWithSingleCall < Base
    property foo : String? = nil
    property bar : String? = nil

    before_schema_validation :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class MultipleAfterSuccessfulValidateCallbacksRegisteredWithMultipleCalls < Base
    property foo : String? = nil
    property bar : String? = nil

    before_schema_validation :set_foo
    before_schema_validation :set_bar

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

    property foo_after_successful : String? = nil
    property shared_after_successful : String? = nil

    property foo_after_failed : String? = nil
    property shared_after_failed : String? = nil

    before_schema_validation :set_one_before
    before_schema_validation :set_two_before
    before_schema_validation :set_foo_before

    after_schema_validation :set_one_after
    after_schema_validation :set_two_after
    after_schema_validation :set_foo_after

    after_successful_schema_validation :set_one_after_successful
    after_successful_schema_validation :set_two_after_successful
    after_successful_schema_validation :set_foo_after_successful

    after_failed_schema_validation :set_one_after_failed
    after_failed_schema_validation :set_two_after_failed
    after_failed_schema_validation :set_foo_after_failed

    after_schema_validation :set_one_after
    after_schema_validation :set_two_after
    after_schema_validation :set_foo_after

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

    private def set_one_after_successful
      self.shared_after_successful = "one"
    end

    private def set_two_after_successful
      self.shared_after_successful = "two"
    end

    private def set_foo_after_successful
      self.foo_after_successful = "set_foo"
    end

    private def set_one_after_failed
      self.shared_after_failed = "one"
    end

    private def set_two_after_failed
      self.shared_after_failed = "two"
    end

    private def set_foo_after_failed
      self.foo_after_failed = "set_foo"
    end
  end

  class Child < Parent
    property abc_before : String? = nil

    property abc_after : String? = nil

    property abc_after_successful : String? = nil

    property abc_after_failed : String? = nil

    before_schema_validation :set_three_before
    before_schema_validation :set_abc_before

    after_schema_validation :set_three_after
    after_schema_validation :set_abc_after

    after_successful_schema_validation :set_three_after_successful
    after_successful_schema_validation :set_abc_after_successful

    after_failed_schema_validation :set_three_after_failed
    after_failed_schema_validation :set_abc_after_failed

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

    private def set_three_after_successful
      self.shared_after_successful = "three"
    end

    private def set_abc_after_successful
      self.abc_after_successful = "set_abc"
    end

    private def set_three_after_failed
      self.shared_after_failed = "three"
    end

    private def set_abc_after_failed
      self.abc_after_failed = "set_abc"
    end
  end
end
