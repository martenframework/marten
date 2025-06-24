require "./spec_helper"

describe Marten::DB::Query::Expression::Annotate do
  describe "#average" do
    it "adds an average annotation with the expected defaults to the annotate object" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.average("posts")

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "average"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_false
      annotate.annotations[0].alias_name.should eq "posts_average"
    end

    it "adds an average annotation with a custom alias name and distinct value" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.average("posts", alias_name: "custom_alias_name", distinct: true)

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "average"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_true
      annotate.annotations[0].alias_name.should eq "custom_alias_name"
    end
  end

  describe "#count" do
    it "adds a count annotation with the expected defaults to the annotate object" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.count("posts")

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "count"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_false
      annotate.annotations[0].alias_name.should eq "posts_count"
    end

    it "adds a count annotation with a custom alias name and distinct value" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.count("posts", alias_name: "custom_alias_name", distinct: true)

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "count"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_true
      annotate.annotations[0].alias_name.should eq "custom_alias_name"
    end
  end

  describe "#maximum" do
    it "adds a maximum annotation with the expected defaults to the annotate object" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.maximum("posts")

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "maximum"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_false
      annotate.annotations[0].alias_name.should eq "posts_maximum"
    end

    it "adds a maximum annotation with a custom alias name and distinct value" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.maximum("posts", alias_name: "custom_alias_name", distinct: true)

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "maximum"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_true
      annotate.annotations[0].alias_name.should eq "custom_alias_name"
    end
  end

  describe "#minimum" do
    it "adds a minimum annotation with the expected defaults to the annotate object" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.minimum("posts")

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "minimum"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_false
      annotate.annotations[0].alias_name.should eq "posts_minimum"
    end

    it "adds a minimum annotation with a custom alias name and distinct value" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.minimum("posts", alias_name: "custom_alias_name", distinct: true)

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "minimum"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_true
      annotate.annotations[0].alias_name.should eq "custom_alias_name"
    end
  end

  describe "#sum" do
    it "adds a sum annotation with the expected defaults to the annotate object" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.sum("posts")

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "sum"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_false
      annotate.annotations[0].alias_name.should eq "posts_sum"
    end

    it "adds a sum annotation with a custom alias name and distinct value" do
      annotate = Marten::DB::Query::Expression::Annotate.new
      annotate.sum("posts", alias_name: "custom_alias_name", distinct: true)

      annotate.annotations.size.should eq 1
      annotate.annotations[0].type.should eq "sum"
      annotate.annotations[0].field.should eq "posts"
      annotate.annotations[0].distinct?.should be_true
      annotate.annotations[0].alias_name.should eq "custom_alias_name"
    end
  end
end
