require "./spec_helper"

describe Marten::DB::Query::SQL::EmptyQuery do
  before_each do
    Tag.create!(name: "crystal", is_active: true)
  end

  describe "#count" do
    it "returns 0" do
      Marten::DB::Query::SQL::EmptyQuery(Tag).new.count.should eq 0
    end
  end

  describe "#execute" do
    it "returns an empty array" do
      Marten::DB::Query::SQL::EmptyQuery(Tag).new.execute.should be_empty
    end
  end

  describe "#exists?" do
    it "returns false" do
      Marten::DB::Query::SQL::EmptyQuery(Tag).new.exists?.should be_false
    end
  end

  describe "#raw_delete" do
    it "returns 0 and does not delete anything" do
      Marten::DB::Query::SQL::EmptyQuery(Tag).new.raw_delete.should eq 0
      Tag.all.size.should eq 1
    end
  end

  describe "#update_with" do
    it "returns 0 and does not update anything" do
      Marten::DB::Query::SQL::EmptyQuery(Tag).new.update_with({"name" => "updated"}).should eq 0
      Tag.filter(name: "updated").size.should eq 0
    end
  end
end
