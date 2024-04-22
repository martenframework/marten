require "./spec_helper"

describe Marten::DB::Management::Column::Enum do
  describe "#==" do
    it "returns true if two column objects are the same" do
      column_1 = Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"])
      column_2 = column_1
      column_1.should eq column_2
    end

    it "returns true if two column objects have the same properties" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"]).should eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"])
      )

      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], null: true).should eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], null: true)
      )

      Marten::DB::Management::Column::Enum.new(
        "test",
        values: ["red", "green", "blue"],
        null: true,
        unique: true,
        default: "red"
      ).should eq(
        Marten::DB::Management::Column::Enum.new(
          "test",
          values: ["red", "green", "blue"],
          null: true,
          unique: true,
          default: "red"
        )
      )
    end

    it "returns false if two column objects don't have the same name" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"]).should_not eq(
        Marten::DB::Management::Column::Enum.new("test2", values: ["red", "green", "blue"])
      )
    end

    it "returns false if two column objects don't have the same values" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"]).should_not eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue", "yellow"])
      )
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::Enum.new(
        "test",
        values: ["red", "green", "blue"],
        primary_key: true
      ).should_not eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], primary_key: false)
      )
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], null: true).should_not eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], null: false)
      )
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], unique: true).should_not eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], unique: false)
      )
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], index: true).should_not eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], index: false)
      )
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], default: "red").should_not eq(
        Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], default: "green")
      )
    end
  end

  describe "#clone" do
    it "returns a cloned object" do
      column_1 = Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"])
      cloned_column_1 = column_1.clone
      cloned_column_1.should_not be column_1
      cloned_column_1.should eq Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"])

      column_2 = Marten::DB::Management::Column::Enum.new("test", null: true, values: ["red", "green", "blue"])
      cloned_column_2 = column_2.clone
      cloned_column_2.should_not be column_2
      cloned_column_2.should eq Marten::DB::Management::Column::Enum.new(
        "test",
        null: true,
        values: ["red", "green", "blue"]
      )

      column_3 = Marten::DB::Management::Column::Enum.new("test", unique: true, values: ["red", "green", "blue"])
      cloned_column_3 = column_3.clone
      cloned_column_3.should_not be column_3
      cloned_column_3.should eq Marten::DB::Management::Column::Enum.new(
        "test",
        unique: true,
        values: ["red", "green", "blue"]
      )

      column_4 = Marten::DB::Management::Column::Enum.new("test", index: true, values: ["red", "green", "blue"])
      cloned_column_4 = column_4.clone
      cloned_column_4.should_not be column_4
      cloned_column_4.should eq Marten::DB::Management::Column::Enum.new(
        "test",
        index: true,
        values: ["red", "green", "blue"]
      )

      column_5 = Marten::DB::Management::Column::Enum.new(
        "test",
        default: "red",
        values: ["red", "green", "blue"]
      )
      cloned_column_5 = column_5.clone
      cloned_column_5.should_not be column_5
      cloned_column_5.should eq Marten::DB::Management::Column::Enum.new(
        "test",
        default: "red",
        values: ["red", "green", "blue"]
      )
    end
  end

  describe "#same_config?" do
    it "returns true if two column objects have different names but have the same properties" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"]).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"])
      ).should be_true

      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"], null: true).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"], null: true)
      ).should be_true

      Marten::DB::Management::Column::Enum.new(
        "foo",
        values: ["red", "green", "blue"],
        null: true,
        unique: true,
        default: "red"
      ).same_config?(
        Marten::DB::Management::Column::Enum.new(
          "bar",
          values: ["red", "green", "blue"],
          null: true,
          unique: true,
          default: "red"
        )
      ).should be_true
    end

    it "returns false if two column objects don't have the same values" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"]).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue", "yellow"])
      ).should be_false
    end

    it "returns false if two column objects don't have the same primary key configuration" do
      Marten::DB::Management::Column::Enum.new(
        "foo",
        values: ["red", "green", "blue"],
        primary_key: true
      ).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"], primary_key: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same null configuration" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"], null: true).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"], null: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same unique configuration" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"], unique: true).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"], unique: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same index configuration" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"], index: true).same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"], index: false)
      ).should be_false
    end

    it "returns false if two column objects don't have the same default value" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"], default: "red").same_config?(
        Marten::DB::Management::Column::Enum.new("bar", values: ["red", "green", "blue"], default: "green")
      ).should be_false
    end

    it "returns false if two column objects have the same properties but are of different classes" do
      Marten::DB::Management::Column::Enum.new("foo", values: ["red", "green", "blue"]).same_config?(
        Marten::DB::Management::Column::Int.new("foo")
      ).should be_false
    end
  end

  describe "#serialize_args" do
    it "returns the arguments needed to recreate the column" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"])
        .serialize_args
        .should eq %{:test, :enum, values: ["red", "green", "blue"]}

      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], null: true)
        .serialize_args
        .should eq %{:test, :enum, values: ["red", "green", "blue"], null: true}

      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"], default: "red")
        .serialize_args
        .should eq %{:test, :enum, values: ["red", "green", "blue"], default: "red"}
    end
  end

  describe "#values" do
    it "returns the values of the enum" do
      Marten::DB::Management::Column::Enum.new("test", values: ["red", "green", "blue"]).values
        .should eq ["red", "green", "blue"]
    end
  end
end
