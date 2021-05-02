require "./spec_helper"

describe Marten::Template::Tag::CanSplitSmartly do
  describe "#split_smartly" do
    it "splits a simple string with multiple words" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is a test").should eq ["this", "is", "a", "test"]
    end

    it "splits a simple string with multiple words and a single quote that is not part of a string literal" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is John's apple").should eq ["this", "is", "John's", "apple"]
    end

    it "splits a simple string with multiple words and a double quote that is not part of a string literal" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is John\"s apple").should eq ["this", "is", "John\"s", "apple"]
    end

    it "splits a simple string with single quote literals" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is 'my super' apple").should eq ["this", "is", "'my super'", "apple"]
    end

    it "splits a simple string with double quote literals" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is \"my super\" apple").should eq ["this", "is", "\"my super\"", "apple"]
    end

    it "splits a simple string with single quote literals containing escaped quotes" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is 'John Doe\\'s' apple").should eq ["this", "is", "'John Doe\\'s'", "apple"]
    end

    it "splits a simple string with double quote literals containing escaped quotes" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly(%{this is "John Doe\\"s" apple}).should eq ["this", "is", %{"John Doe\\"s"}, "apple"]
    end

    it "splits a simple string with an arg-like single quote literals" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly("this is an arg:'apple'").should eq ["this", "is", "an", "arg:'apple'"]
    end

    it "splits a simple string with an arg-like single quote literals" do
      spliter = Marten::Template::Tag::CanSplitSmartly::Test.new
      spliter.split_smartly(%{this is an arg:"apple"}).should eq ["this", "is", "an", %{arg:"apple"}]
    end
  end
end

class Marten::Template::Tag::CanSplitSmartly::Test
  include Marten::Template::Tag::CanSplitSmartly
end
