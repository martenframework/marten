require "./spec_helper"

describe Marten::Routing::TranslatedPath do
  describe "#==" do
    it "returns true if the objects are the same" do
      path1 = Marten::Routing::TranslatedPath.new("path.to.translation")
      path2 = path1

      path1.should eq path2
    end

    it "returns true if the keys are the same" do
      path1 = Marten::Routing::TranslatedPath.new("path.to.translation")
      path2 = Marten::Routing::TranslatedPath.new("path.to.translation")

      path1.should eq path2
    end

    it "returns false if the keys are different" do
      path1 = Marten::Routing::TranslatedPath.new("path.to.translation")
      path2 = Marten::Routing::TranslatedPath.new("other.translation")

      path1.should_not eq path2
    end
  end

  describe "#key" do
    it "returns the key of the translated path" do
      path = Marten::Routing::TranslatedPath.new("path.to.translation")

      path.key.should eq "path.to.translation"
    end
  end

  describe "#to_s" do
    it "returns the translated path" do
      path = Marten::Routing::TranslatedPath.new("simple.translation")

      path.to_s.should eq "This is a simple translation"
    end
  end
end
