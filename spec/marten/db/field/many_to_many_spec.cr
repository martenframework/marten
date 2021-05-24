require "./spec_helper"

describe Marten::DB::Field::ManyToMany do
  describe "#db_column" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.db_column.should be_nil
    end
  end

  describe "#default" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.default.should be_nil
    end
  end

  describe "#from_db_result_set" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 42") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#related_model" do
    it "returns the related model" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.related_model.should eq Tag
    end
  end

  describe "#relation?" do
    it "returns true" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.relation?.should be_true
    end
  end

  describe "#relation_name" do
    it "returns the relation name" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.relation_name.should eq "tags"
    end
  end

  describe "#to_column" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.to_column.should be_nil
    end
  end

  describe "#to_db" do
    it "always returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.to_db(nil).should be_nil
    end
  end
end
