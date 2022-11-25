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

  describe "::after_create_commit" do
    it "allows to register a single after_create_commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_create_commit")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_create_commit callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_create_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_create_commit callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_create_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_create_rollback" do
    it "allows to register a single after_create_rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_create_rollback")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_create_rollback callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_create_rollback")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_create_rollback callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_create_rollback")

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

  describe "::after_update_commit" do
    it "allows to register a single after_update_commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_update_commit")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_update_commit callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_update_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_update_commit callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_update_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_update_rollback" do
    it "allows to register a single after_update_rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_update_rollback")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_update_rollback callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_update_rollback")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_update_rollback callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_update_rollback")

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

  describe "::after_save_commit" do
    it "allows to register a single after_save_commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_save_commit")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_save_commit callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_save_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_save_commit callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_save_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_save_rollback" do
    it "allows to register a single after_save_rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_save_rollback")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_save_rollback callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_save_rollback")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_save_rollback callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_save_rollback")

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

  describe "::after_delete_commit" do
    it "allows to register a single after_delete_commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_delete_commit")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_delete_commit callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_delete_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_delete_commit callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_delete_commit")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_delete_rollback" do
    it "allows to register a single after_delete_rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.foo.should be_nil

      obj.run_callbacks("after_delete_rollback")

      obj.foo.should eq "set_foo"
    end

    it "allows to register multiple after_delete_rollback callbacks through a single call" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithSingleCall.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_delete_rollback")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end

    it "allows to register multiple after_delete_rollback callbacks through multiple calls" do
      obj = Marten::DB::Model::CallbacksSpec::MultipleAfterCallbacksRegisteredWithMultipleCalls.new

      obj.foo.should be_nil
      obj.bar.should be_nil

      obj.run_callbacks("after_delete_rollback")

      obj.foo.should eq "set_foo"
      obj.bar.should eq "set_bar"
    end
  end

  describe "::after_commit" do
    it "allows to register a single after_commit callback for all the actions if the on argument is not used" do
      obj_1 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithoutActions.new
      obj_1.foo.should be_nil
      obj_1.run_callbacks("after_create_commit")
      obj_1.foo.should eq "set_foo"

      obj_2 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithoutActions.new
      obj_2.foo.should be_nil
      obj_2.run_callbacks("after_update_commit")
      obj_2.foo.should eq "set_foo"

      obj_3 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithoutActions.new
      obj_3.foo.should be_nil
      obj_3.run_callbacks("after_delete_commit")
      obj_3.foo.should eq "set_foo"
    end

    it "allows to register multiple after_commit callbacks for all the actions if the on argument is not used" do
      obj_1 = Marten::DB::Model::CallbacksSpec::MultipleAfterCommitCallbacksRegisteredWithSingleCallWithoutActions.new
      obj_1.foo.should be_nil
      obj_1.bar.should be_nil
      obj_1.run_callbacks("after_create_commit")
      obj_1.foo.should eq "set_foo"
      obj_1.bar.should eq "set_bar"

      obj_2 = Marten::DB::Model::CallbacksSpec::MultipleAfterCommitCallbacksRegisteredWithSingleCallWithoutActions.new
      obj_2.foo.should be_nil
      obj_2.bar.should be_nil
      obj_2.run_callbacks("after_update_commit")
      obj_2.foo.should eq "set_foo"
      obj_2.bar.should eq "set_bar"

      obj_3 = Marten::DB::Model::CallbacksSpec::MultipleAfterCommitCallbacksRegisteredWithSingleCallWithoutActions.new
      obj_3.foo.should be_nil
      obj_3.bar.should be_nil
      obj_3.run_callbacks("after_delete_commit")
      obj_3.foo.should eq "set_foo"
      obj_3.bar.should eq "set_bar"
    end

    it "allows to register a single after_commit callback for a specific action" do
      obj_1 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithSingleAction.new
      obj_1.foo.should be_nil
      obj_1.run_callbacks("after_create_commit")
      obj_1.foo.should eq "set_foo_on_create"

      obj_2 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithSingleAction.new
      obj_2.foo.should be_nil
      obj_2.run_callbacks("after_update_commit")
      obj_2.foo.should eq "set_foo_on_update"

      obj_3 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithSingleAction.new
      obj_3.foo.should be_nil
      obj_3.run_callbacks("after_save_commit")
      obj_3.foo.should eq "set_foo_on_save"

      obj_4 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithSingleAction.new
      obj_4.foo.should be_nil
      obj_4.run_callbacks("after_delete_commit")
      obj_4.foo.should eq "set_foo_on_delete"
    end

    it "allows to register a single after_commit callback for multiple specific actions" do
      obj_1 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new
      obj_1.foo.should be_nil
      obj_1.run_callbacks("after_create_commit")
      obj_1.foo.should eq "set_foo_on_create_or_update"

      obj_2 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new
      obj_2.foo.should be_nil
      obj_2.run_callbacks("after_update_commit")
      obj_2.foo.should eq "set_foo_on_create_or_update"

      obj_3 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new
      obj_3.foo.should be_nil
      obj_3.run_callbacks("after_save_commit")
      obj_3.foo.should eq "set_foo_on_save_or_delete"

      obj_4 = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new
      obj_4.foo.should be_nil
      obj_4.run_callbacks("after_delete_commit")
      obj_4.foo.should eq "set_foo_on_save_or_delete"
    end
  end

  describe "::after_rollback" do
    it "allows to register a single after_rollback callback for all the actions if the on argument is not used" do
      obj_1 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithoutActions.new
      obj_1.foo.should be_nil
      obj_1.run_callbacks("after_create_rollback")
      obj_1.foo.should eq "set_foo"

      obj_2 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithoutActions.new
      obj_2.foo.should be_nil
      obj_2.run_callbacks("after_update_rollback")
      obj_2.foo.should eq "set_foo"

      obj_3 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithoutActions.new
      obj_3.foo.should be_nil
      obj_3.run_callbacks("after_delete_rollback")
      obj_3.foo.should eq "set_foo"
    end

    it "allows to register multiple after_rollback callbacks for all the actions if the on argument is not used" do
      obj_1 = Marten::DB::Model::CallbacksSpec::MultipleAfterRollbackCallbacksRegisteredWithSingleCallWithoutActions.new
      obj_1.foo.should be_nil
      obj_1.bar.should be_nil
      obj_1.run_callbacks("after_create_rollback")
      obj_1.foo.should eq "set_foo"
      obj_1.bar.should eq "set_bar"

      obj_2 = Marten::DB::Model::CallbacksSpec::MultipleAfterRollbackCallbacksRegisteredWithSingleCallWithoutActions.new
      obj_2.foo.should be_nil
      obj_2.bar.should be_nil
      obj_2.run_callbacks("after_update_rollback")
      obj_2.foo.should eq "set_foo"
      obj_2.bar.should eq "set_bar"

      obj_3 = Marten::DB::Model::CallbacksSpec::MultipleAfterRollbackCallbacksRegisteredWithSingleCallWithoutActions.new
      obj_3.foo.should be_nil
      obj_3.bar.should be_nil
      obj_3.run_callbacks("after_delete_rollback")
      obj_3.foo.should eq "set_foo"
      obj_3.bar.should eq "set_bar"
    end

    it "allows to register a single after_rollback callback for a specific action" do
      obj_1 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithSingleAction.new
      obj_1.foo.should be_nil
      obj_1.run_callbacks("after_create_rollback")
      obj_1.foo.should eq "set_foo_on_create"

      obj_2 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithSingleAction.new
      obj_2.foo.should be_nil
      obj_2.run_callbacks("after_update_rollback")
      obj_2.foo.should eq "set_foo_on_update"

      obj_3 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithSingleAction.new
      obj_3.foo.should be_nil
      obj_3.run_callbacks("after_save_rollback")
      obj_3.foo.should eq "set_foo_on_save"

      obj_4 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithSingleAction.new
      obj_4.foo.should be_nil
      obj_4.run_callbacks("after_delete_rollback")
      obj_4.foo.should eq "set_foo_on_delete"
    end

    it "allows to register a single after_rollback callback for multiple specific actions" do
      obj_1 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new
      obj_1.foo.should be_nil
      obj_1.run_callbacks("after_create_rollback")
      obj_1.foo.should eq "set_foo_on_create_or_update"

      obj_2 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new
      obj_2.foo.should be_nil
      obj_2.run_callbacks("after_update_rollback")
      obj_2.foo.should eq "set_foo_on_create_or_update"

      obj_3 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new
      obj_3.foo.should be_nil
      obj_3.run_callbacks("after_save_rollback")
      obj_3.foo.should eq "set_foo_on_save_or_delete"

      obj_4 = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new
      obj_4.foo.should be_nil
      obj_4.run_callbacks("after_delete_rollback")
      obj_4.foo.should eq "set_foo_on_save_or_delete"
    end
  end

  describe "#has_after_create_commit_callbacks?" do
    it "returns false by default if the model does not have any create commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_create_commit").should be_false
    end

    it "returns true the model does has create commit callbacks defined using #after_create_commit" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_create_commit").should be_true
    end

    it "returns true the model does has create commit callbacks defined using #after_commit and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithOneAction.new

      obj.has_callbacks?("after_create_commit").should be_true
    end

    it "returns true the model does has create commit callbacks defined using #after_commit and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new

      obj.has_callbacks?("after_create_commit").should be_true
    end
  end

  describe "#has_after_create_rollback_callbacks?" do
    it "returns false by default if the model does not have any create rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_create_rollback").should be_false
    end

    it "returns true the model does has create commit callbacks defined using #after_create_rollback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_create_rollback").should be_true
    end

    it "returns true the model does has create commit callbacks defined using #after_rollback and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithOneAction.new

      obj.has_callbacks?("after_create_rollback").should be_true
    end

    it "returns true the model does has create commit callbacks defined using #after_rollback and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new

      obj.has_callbacks?("after_create_rollback").should be_true
    end
  end

  describe "#has_after_delete_commit_callbacks?" do
    it "returns false by default if the model does not have any delete commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_delete_commit").should be_false
    end

    it "returns true the model does has delete commit callbacks defined using #after_delete_commit" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_delete_commit").should be_true
    end

    it "returns true the model does has delete commit callbacks defined using #after_commit and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithOneAction.new

      obj.has_callbacks?("after_delete_commit").should be_true
    end

    it "returns true the model does has delete commit callbacks defined using #after_commit and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new

      obj.has_callbacks?("after_delete_commit").should be_true
    end
  end

  describe "#has_after_delete_rollback_callbacks?" do
    it "returns false by default if the model does not have any delete rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_delete_rollback").should be_false
    end

    it "returns true the model does has delete commit callbacks defined using #after_delete_rollback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_delete_rollback").should be_true
    end

    it "returns true the model does has delete commit callbacks defined using #after_rollback and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithOneAction.new

      obj.has_callbacks?("after_delete_rollback").should be_true
    end

    it "returns true the model does has delete commit callbacks defined using #after_rollback and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new

      obj.has_callbacks?("after_delete_rollback").should be_true
    end
  end

  describe "#has_after_save_commit_callbacks?" do
    it "returns false by default if the model does not have any save commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_save_commit").should be_false
    end

    it "returns true the model does has save commit callbacks defined using #after_save_commit" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_save_commit").should be_true
    end

    it "returns true the model does has save commit callbacks defined using #after_commit and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithOneAction.new

      obj.has_callbacks?("after_save_commit").should be_true
    end

    it "returns true the model does has save commit callbacks defined using #after_commit and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new

      obj.has_callbacks?("after_save_commit").should be_true
    end
  end

  describe "#has_after_save_rollback_callbacks?" do
    it "returns false by default if the model does not have any save rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_save_rollback").should be_false
    end

    it "returns true the model does has save commit callbacks defined using #after_save_rollback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_save_rollback").should be_true
    end

    it "returns true the model does has save commit callbacks defined using #after_rollback and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithOneAction.new

      obj.has_callbacks?("after_save_rollback").should be_true
    end

    it "returns true the model does has save commit callbacks defined using #after_rollback and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new

      obj.has_callbacks?("after_save_rollback").should be_true
    end
  end

  describe "#has_after_update_commit_callbacks?" do
    it "returns false by default if the model does not have any update commit callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_update_commit").should be_false
    end

    it "returns true the model does has update commit callbacks defined using #after_update_commit" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_update_commit").should be_true
    end

    it "returns true the model does has update commit callbacks defined using #after_commit and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithOneAction.new

      obj.has_callbacks?("after_update_commit").should be_true
    end

    it "returns true the model does has update commit callbacks defined using #after_commit and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCommitCallbackWithMultipleActions.new

      obj.has_callbacks?("after_update_commit").should be_true
    end
  end

  describe "#has_after_update_rollback_callbacks?" do
    it "returns false by default if the model does not have any update rollback callback" do
      obj = Marten::DB::Model::CallbacksSpec::Base.new

      obj.has_callbacks?("after_update_rollback").should be_false
    end

    it "returns true the model does has update commit callbacks defined using #after_update_rollback" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterCallback.new

      obj.has_callbacks?("after_update_rollback").should be_true
    end

    it "returns true the model does has update commit callbacks defined using #after_rollback and one action" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithOneAction.new

      obj.has_callbacks?("after_update_rollback").should be_true
    end

    it "returns true the model does has update commit callbacks defined using #after_rollback and multiple actions" do
      obj = Marten::DB::Model::CallbacksSpec::SingleAfterRollbackCallbackWithMultipleActions.new

      obj.has_callbacks?("after_update_rollback").should be_true
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

  describe "#run_after_create_commit_callbacks" do
    it "runs the after create commit callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_create_commit")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_create_commit")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_create_rollback_callbacks" do
    it "runs the after create rollback callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_create_rollback")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_create_rollback")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_update_commit_callbacks" do
    it "runs the after update commit callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_update_commit")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_update_commit")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_update_rollback_callbacks" do
    it "runs the after update rollback callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_update_rollback")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_update_rollback")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_save_commit_callbacks" do
    it "runs the after save commit callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_save_commit")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_save_commit")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_save_rollback_callbacks" do
    it "runs the after save rollback callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_save_rollback")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_save_rollback")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_delete_commit_callbacks" do
    it "runs the after delete commit callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_delete_commit")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_delete_commit")

      obj.shared_after.should eq "three"
      obj.foo_after.should eq "set_foo"
      obj.abc_after.should eq "set_abc"
    end
  end

  describe "#run_after_delete_rollback_callbacks" do
    it "runs the after delete rollback callbacks in the order they were registered" do
      obj = Marten::DB::Model::CallbacksSpec::Parent.new

      obj.shared_after.should be_nil

      obj.run_callbacks("after_delete_rollback")

      obj.shared_after.should eq "two"
    end

    it "runs inherited callbacks as well as local callbacks" do
      obj = Marten::DB::Model::CallbacksSpec::Child.new

      obj.shared_after.should be_nil
      obj.foo_after.should be_nil
      obj.abc_after.should be_nil

      obj.run_callbacks("after_delete_rollback")

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

    def has_callbacks?(callback)
      return has_after_create_commit_callbacks? if callback == "after_create_commit"
      return has_after_update_commit_callbacks? if callback == "after_update_commit"
      return has_after_save_commit_callbacks? if callback == "after_save_commit"
      return has_after_delete_commit_callbacks? if callback == "after_delete_commit"
      return has_after_create_rollback_callbacks? if callback == "after_create_rollback"
      return has_after_update_rollback_callbacks? if callback == "after_update_rollback"
      return has_after_save_rollback_callbacks? if callback == "after_save_rollback"
      return has_after_delete_rollback_callbacks? if callback == "after_delete_rollback"
    end

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
      run_after_create_commit_callbacks if callback.nil? || callback == "after_create_commit"
      run_after_update_commit_callbacks if callback.nil? || callback == "after_update_commit"
      run_after_save_commit_callbacks if callback.nil? || callback == "after_save_commit"
      run_after_delete_commit_callbacks if callback.nil? || callback == "after_delete_commit"
      run_after_create_rollback_callbacks if callback.nil? || callback == "after_create_rollback"
      run_after_update_rollback_callbacks if callback.nil? || callback == "after_update_rollback"
      run_after_save_rollback_callbacks if callback.nil? || callback == "after_save_rollback"
      run_after_delete_rollback_callbacks if callback.nil? || callback == "after_delete_rollback"
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
    after_create_commit :set_foo
    after_update_commit :set_foo
    after_save_commit :set_foo
    after_delete_commit :set_foo
    after_create_rollback :set_foo
    after_update_rollback :set_foo
    after_save_rollback :set_foo
    after_delete_rollback :set_foo

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
    after_create_commit :set_foo, :set_bar
    after_update_commit :set_foo, :set_bar
    after_save_commit :set_foo, :set_bar
    after_delete_commit :set_foo, :set_bar
    after_create_rollback :set_foo, :set_bar
    after_update_rollback :set_foo, :set_bar
    after_save_rollback :set_foo, :set_bar
    after_delete_rollback :set_foo, :set_bar

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
    after_create_commit :set_foo
    after_create_commit :set_bar
    after_update_commit :set_foo
    after_update_commit :set_bar
    after_save_commit :set_foo
    after_save_commit :set_bar
    after_delete_commit :set_foo
    after_delete_commit :set_bar
    after_create_rollback :set_foo
    after_create_rollback :set_bar
    after_update_rollback :set_foo
    after_update_rollback :set_bar
    after_save_rollback :set_foo
    after_save_rollback :set_bar
    after_delete_rollback :set_foo
    after_delete_rollback :set_bar

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

    after_create_commit :set_one_after
    after_create_commit :set_two_after
    after_create_commit :set_foo_after

    after_update_commit :set_one_after
    after_update_commit :set_two_after
    after_update_commit :set_foo_after

    after_save_commit :set_one_after
    after_save_commit :set_two_after
    after_save_commit :set_foo_after

    after_delete_commit :set_one_after
    after_delete_commit :set_two_after
    after_delete_commit :set_foo_after

    after_create_rollback :set_one_after
    after_create_rollback :set_two_after
    after_create_rollback :set_foo_after

    after_update_rollback :set_one_after
    after_update_rollback :set_two_after
    after_update_rollback :set_foo_after

    after_save_rollback :set_one_after
    after_save_rollback :set_two_after
    after_save_rollback :set_foo_after

    after_delete_rollback :set_one_after
    after_delete_rollback :set_two_after
    after_delete_rollback :set_foo_after

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

    after_create_commit :set_three_after
    after_create_commit :set_abc_after

    after_update_commit :set_three_after
    after_update_commit :set_abc_after

    after_save_commit :set_three_after
    after_save_commit :set_abc_after

    after_delete_commit :set_three_after
    after_delete_commit :set_abc_after

    after_create_rollback :set_three_after
    after_create_rollback :set_abc_after

    after_update_rollback :set_three_after
    after_update_rollback :set_abc_after

    after_save_rollback :set_three_after
    after_save_rollback :set_abc_after

    after_delete_rollback :set_three_after
    after_delete_rollback :set_abc_after

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

  class SingleAfterCommitCallbackWithoutActions < Base
    property foo : String? = nil

    after_commit :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterCommitCallbacksRegisteredWithSingleCallWithoutActions < Base
    property foo : String? = nil
    property bar : String? = nil

    after_commit :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterCommitCallbackWithSingleAction < Base
    property foo : String? = nil

    after_commit :set_foo_on_create, on: :create
    after_commit :set_foo_on_update, on: :update
    after_commit :set_foo_on_save, on: :save
    after_commit :set_foo_on_delete, on: :delete

    private def set_foo_on_create
      self.foo = "set_foo_on_create"
    end

    private def set_foo_on_update
      self.foo = "set_foo_on_update"
    end

    private def set_foo_on_save
      self.foo = "set_foo_on_save"
    end

    private def set_foo_on_delete
      self.foo = "set_foo_on_delete"
    end
  end

  class SingleAfterCommitCallbackWithMultipleActions < Base
    property foo : String? = nil

    after_commit :set_foo_on_create_or_update, on: [:create, :update]
    after_commit :set_foo_on_save_or_delete, on: [:save, :delete]

    private def set_foo_on_create_or_update
      self.foo = "set_foo_on_create_or_update"
    end

    private def set_foo_on_save_or_delete
      self.foo = "set_foo_on_save_or_delete"
    end
  end

  class SingleAfterRollbackCallbackWithoutActions < Base
    property foo : String? = nil

    after_rollback :set_foo

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class MultipleAfterRollbackCallbacksRegisteredWithSingleCallWithoutActions < Base
    property foo : String? = nil
    property bar : String? = nil

    after_rollback :set_foo, :set_bar

    private def set_foo
      self.foo = "set_foo"
    end

    private def set_bar
      self.bar = "set_bar"
    end
  end

  class SingleAfterRollbackCallbackWithSingleAction < Base
    property foo : String? = nil

    after_rollback :set_foo_on_create, on: :create
    after_rollback :set_foo_on_update, on: :update
    after_rollback :set_foo_on_save, on: :save
    after_rollback :set_foo_on_delete, on: :delete

    private def set_foo_on_create
      self.foo = "set_foo_on_create"
    end

    private def set_foo_on_update
      self.foo = "set_foo_on_update"
    end

    private def set_foo_on_save
      self.foo = "set_foo_on_save"
    end

    private def set_foo_on_delete
      self.foo = "set_foo_on_delete"
    end
  end

  class SingleAfterRollbackCallbackWithMultipleActions < Base
    property foo : String? = nil

    after_rollback :set_foo_on_create_or_update, on: [:create, :update]
    after_rollback :set_foo_on_save_or_delete, on: [:save, :delete]

    private def set_foo_on_create_or_update
      self.foo = "set_foo_on_create_or_update"
    end

    private def set_foo_on_save_or_delete
      self.foo = "set_foo_on_save_or_delete"
    end
  end

  class SingleAfterCommitCallbackWithOneAction < Base
    property foo : String? = nil

    after_commit :set_foo, on: :create
    after_commit :set_foo, on: :update
    after_commit :set_foo, on: :save
    after_commit :set_foo, on: :delete

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class SingleAfterRollbackCallbackWithOneAction < Base
    property foo : String? = nil

    after_rollback :set_foo, on: :create
    after_rollback :set_foo, on: :update
    after_rollback :set_foo, on: :save
    after_rollback :set_foo, on: :delete

    private def set_foo
      self.foo = "set_foo"
    end
  end

  class SingleAfterRollbackCallbackWithOneAction < Base
    property foo : String? = nil

    after_rollback :set_foo, on: :create
    after_rollback :set_foo, on: :update
    after_rollback :set_foo, on: :save
    after_rollback :set_foo, on: :delete

    private def set_foo
      self.foo = "set_foo"
    end
  end
end
