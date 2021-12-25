require "./spec_helper"

describe Marten::DB::Model::Inheritance do
  describe "::abstract?" do
    it "returns true if the model is abstract" do
      AbstractArticle.abstract?.should be_true
    end

    it "returns false if the model is not abstract" do
      Post.abstract?.should be_false
    end
  end
end
