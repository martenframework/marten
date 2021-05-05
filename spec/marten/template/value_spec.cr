require "./spec_helper"

describe Marten::Template::Value do
  describe "#each" do
    it "yields the keys of a specific hash" do
      value = Marten::Template::Value.from({"foo" => "bar", "test" => 42})

      arr = [] of Marten::Template::Value
      value.each { |v| arr << v }

      arr.size.should eq 2
      arr[0].should eq Marten::Template::Value.from("foo")
      arr[1].should eq Marten::Template::Value.from("test")
    end

    it "yields the value of a specific array" do
      value = Marten::Template::Value.from([42, "foo", "bar"])

      arr = [] of Marten::Template::Value
      value.each { |v| arr << v }

      arr.size.should eq 3
      arr[0].should eq Marten::Template::Value.from(42)
      arr[1].should eq Marten::Template::Value.from("foo")
      arr[2].should eq Marten::Template::Value.from("bar")
    end

    it "raises an unsupported type exception if the underlying object is not iterable" do
      value = Marten::Template::Value.from(42)
      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Int32 objects are not iterable"
      ) do
        value.each { }
      end
    end
  end
end
