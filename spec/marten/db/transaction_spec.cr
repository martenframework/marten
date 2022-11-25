require "./spec_helper"

describe Marten::DB::Transaction do
  describe "#connection" do
    it "returns the transaction connection" do
      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)
          transaction.connection.should eq conn
        end
      end
    end
  end

  describe "#notify_observers" do
    it "notifies the commit observers only when a transaction is committed" do
      commit_notified_1 = false
      commit_notified_2 = false
      rollback_notified_1 = false
      rollback_notified_2 = false

      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)

          transaction.observe_commit(->{ commit_notified_1 = true; nil })
          transaction.observe_commit(->{ commit_notified_2 = true; nil })
          transaction.observe_rollback(->{ rollback_notified_1 = true; nil })
          transaction.observe_rollback(->{ rollback_notified_2 = true; nil })

          transaction.notify_observers
        end
      end

      commit_notified_1.should be_true
      commit_notified_2.should be_true
      rollback_notified_1.should be_false
      rollback_notified_2.should be_false
    end

    it "notifies the rollback observers only when a transaction is rolled back" do
      commit_notified_1 = false
      commit_notified_2 = false
      rollback_notified_1 = false
      rollback_notified_2 = false

      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)

          transaction.observe_commit(->{ commit_notified_1 = true; nil })
          transaction.observe_commit(->{ commit_notified_2 = true; nil })
          transaction.observe_rollback(->{ rollback_notified_1 = true; nil })
          transaction.observe_rollback(->{ rollback_notified_2 = true; nil })

          transaction.rolled_back = true

          transaction.notify_observers
        end
      end

      commit_notified_1.should be_false
      commit_notified_2.should be_false
      rollback_notified_1.should be_true
      rollback_notified_2.should be_true
    end
  end

  describe "#observe_commit" do
    it "allows to add a commit observer to the transaction" do
      commit_notified = false

      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)
          transaction.observe_commit(->{ commit_notified = true; nil })
          transaction.notify_observers
        end
      end

      commit_notified.should be_true
    end
  end

  describe "#observe_rollback" do
    it "allows to add a rollback observer to the transaction" do
      rollback_notified = false

      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)
          transaction.observe_rollback(->{ rollback_notified = true; nil })
          transaction.rolled_back = true
          transaction.notify_observers
        end
      end

      rollback_notified.should be_true
    end
  end

  describe "#rolled_back?" do
    it "returns false by default" do
      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)
          transaction.rolled_back?.should be_false
        end
      end
    end

    it "returns true if the transaction was rolled back" do
      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)
          transaction.rolled_back = true
          transaction.rolled_back?.should be_true
        end
      end
    end
  end

  describe "#rolled_back=" do
    it "allows to mark a transaction as rolled back" do
      Marten::DB::Connection.default.open do |conn|
        conn.transaction do |trx|
          transaction = Marten::DB::Transaction.new(trx)
          transaction.rolled_back = true
          transaction.rolled_back?.should be_true
        end
      end
    end
  end
end
