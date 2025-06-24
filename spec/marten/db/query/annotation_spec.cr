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
end
