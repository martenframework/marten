require "./spec_helper"

describe Marten::DB::Query::Annotation do
  describe "::average" do
    it "creates a new annotation with the average type that is not distinct by default with a default alias name" do
      ann = Marten::DB::Query::Annotation.average("posts")

      ann.type.should eq "average"
      ann.field.should eq "posts"
      ann.distinct?.should be_false
      ann.alias_name.should eq "posts_average"
    end

    it "creates a new annotation with the average type with custom alias name and distinct value" do
      ann = Marten::DB::Query::Annotation.average("posts", alias_name: "custom_alias_name", distinct: true)

      ann.type.should eq "average"
      ann.field.should eq "posts"
      ann.distinct?.should be_true
      ann.alias_name.should eq "custom_alias_name"
    end
  end

  describe "::count" do
    it "creates a new annotation with the count type that is not distinct by default with a default alias name" do
      ann = Marten::DB::Query::Annotation.count("posts")

      ann.type.should eq "count"
      ann.field.should eq "posts"
      ann.distinct?.should be_false
      ann.alias_name.should eq "posts_count"
    end

    it "creates a new annotation with the count type with custom alias name and distinct value" do
      ann = Marten::DB::Query::Annotation.count("posts", alias_name: "custom_alias_name", distinct: true)

      ann.type.should eq "count"
      ann.field.should eq "posts"
      ann.distinct?.should be_true
      ann.alias_name.should eq "custom_alias_name"
    end
  end

  describe "::maximum" do
    it "creates a new annotation with the maximum type that is not distinct by default with a default alias name" do
      ann = Marten::DB::Query::Annotation.maximum("posts")

      ann.type.should eq "maximum"
      ann.field.should eq "posts"
      ann.distinct?.should be_false
      ann.alias_name.should eq "posts_maximum"
    end

    it "creates a new annotation with the maximum type with custom alias name and distinct value" do
      ann = Marten::DB::Query::Annotation.maximum("posts", alias_name: "custom_alias_name", distinct: true)

      ann.type.should eq "maximum"
      ann.field.should eq "posts"
      ann.distinct?.should be_true
      ann.alias_name.should eq "custom_alias_name"
    end
  end

  describe "::minimum" do
    it "creates a new annotation with the minimum type that is not distinct by default with a default alias name" do
      ann = Marten::DB::Query::Annotation.minimum("posts")

      ann.type.should eq "minimum"
      ann.field.should eq "posts"
      ann.distinct?.should be_false
      ann.alias_name.should eq "posts_minimum"
    end

    it "creates a new annotation with the minimum type with custom alias name and distinct value" do
      ann = Marten::DB::Query::Annotation.minimum("posts", alias_name: "custom_alias_name", distinct: true)

      ann.type.should eq "minimum"
      ann.field.should eq "posts"
      ann.distinct?.should be_true
      ann.alias_name.should eq "custom_alias_name"
    end
  end

  describe "::sum" do
    it "creates a new annotation with the sum type that is not distinct by default with a default alias name" do
      ann = Marten::DB::Query::Annotation.sum("posts")

      ann.type.should eq "sum"
      ann.field.should eq "posts"
      ann.distinct?.should be_false
      ann.alias_name.should eq "posts_sum"
    end

    it "creates a new annotation with the sum type with custom alias name and distinct value" do
      ann = Marten::DB::Query::Annotation.sum("posts", alias_name: "custom_alias_name", distinct: true)

      ann.type.should eq "sum"
      ann.field.should eq "posts"
      ann.distinct?.should be_true
      ann.alias_name.should eq "custom_alias_name"
    end
  end

  describe "#alias" do
    it "allows to set the alias name for the annotation" do
      ann = Marten::DB::Query::Annotation.average("posts")
      ann.alias("custom_alias_name").should be ann

      ann.alias_name.should eq "custom_alias_name"
    end
  end

  describe "#distinct" do
    it "allows to set the distinct value for the annotation" do
      ann_1 = Marten::DB::Query::Annotation.average("posts")
      ann_1.distinct(true).should be ann_1
      ann_1.distinct?.should be_true

      ann_2 = Marten::DB::Query::Annotation.average("posts")
      ann_2.distinct(true).should be ann_2
      ann_2.distinct?.should be_true

      ann_3 = Marten::DB::Query::Annotation.average("posts")
      ann_3.distinct(false).should be ann_3
      ann_3.distinct?.should be_false
    end
  end
end
