require "./spec_helper"

describe Marten::Template::Value do
  describe "::from" do
    it "is able to initialize a new value value from a hash" do
      value = Marten::Template::Value.from({"foo" => "bar", "test" => 42, "nested" => {"test" => 1}})

      value.raw.should be_a Hash(Marten::Template::Value, Marten::Template::Value)
      raw = value.raw.as(Hash(Marten::Template::Value, Marten::Template::Value))

      raw.keys.should eq([
        Marten::Template::Value.from("foo"),
        Marten::Template::Value.from("test"),
        Marten::Template::Value.from("nested"),
      ])

      raw[Marten::Template::Value.from("foo")].should eq Marten::Template::Value.from("bar")
      raw[Marten::Template::Value.from("test")].should eq Marten::Template::Value.from(42)
      raw[Marten::Template::Value.from("nested")].should eq Marten::Template::Value.from({"test" => 1})
    end

    it "is able to initialize a new value value from a named tuple" do
      value = Marten::Template::Value.from({foo: "bar", test: 42, nested: {test: 1}})

      value.raw.should be_a Hash(Marten::Template::Value, Marten::Template::Value)
      raw = value.raw.as(Hash(Marten::Template::Value, Marten::Template::Value))

      raw.keys.should eq([
        Marten::Template::Value.from("foo"),
        Marten::Template::Value.from("test"),
        Marten::Template::Value.from("nested"),
      ])

      raw[Marten::Template::Value.from("foo")].should eq Marten::Template::Value.from("bar")
      raw[Marten::Template::Value.from("test")].should eq Marten::Template::Value.from(42)
      raw[Marten::Template::Value.from("nested")].should eq Marten::Template::Value.from({"test" => 1})
    end

    it "is able to initialize a new value value from an array" do
      value = Marten::Template::Value.from(["foo", "bar", 42, {"test" => 1}])

      value.raw.should be_a Array(Marten::Template::Value)
      raw = value.raw.as(Array(Marten::Template::Value))

      raw.should eq([
        Marten::Template::Value.from("foo"),
        Marten::Template::Value.from("bar"),
        Marten::Template::Value.from(42),
        Marten::Template::Value.from({"test" => 1}),
      ])
    end

    it "is able to initialize a new value value from a tuple" do
      value = Marten::Template::Value.from({"foo", "bar", 42, {"test" => 1}})

      value.raw.should be_a Array(Marten::Template::Value)
      raw = value.raw.as(Array(Marten::Template::Value))

      raw.should eq([
        Marten::Template::Value.from("foo"),
        Marten::Template::Value.from("bar"),
        Marten::Template::Value.from(42),
        Marten::Template::Value.from({"test" => 1}),
      ])
    end

    it "is able to initialize a new value value from a range" do
      value = Marten::Template::Value.from((1..4))

      value.raw.should be_a Array(Marten::Template::Value)
      raw = value.raw.as(Array(Marten::Template::Value))

      raw.should eq([
        Marten::Template::Value.from(1),
        Marten::Template::Value.from(2),
        Marten::Template::Value.from(3),
        Marten::Template::Value.from(4),
      ])
    end

    it "is able to initialize a new value value from a char" do
      value = Marten::Template::Value.from('x')
      value.raw.should eq "x"
    end

    it "is able to initialize a new value value from an array of template values" do
      other_value = Marten::Template::Value.from(["foo", "bar", 42])
      value = Marten::Template::Value.from(other_value)
      value.should eq Marten::Template::Value.from(["foo", "bar", 42])
    end

    it "is able to initialize a new value value from a bool" do
      Marten::Template::Value.from(true).raw.should eq true
      Marten::Template::Value.from(false).raw.should eq false
    end

    it "is able to initialize a new value value from a float" do
      Marten::Template::Value.from(12.42).raw.should eq 12.42
    end

    it "is able to initialize a new value value from a hash of template values" do
      other_value = Marten::Template::Value.from({"foo" => "bar", "test" => 42})
      value = Marten::Template::Value.from(other_value)
      value.should eq Marten::Template::Value.from({"foo" => "bar", "test" => 42})
    end

    it "is able to initialize a new value value from an integer" do
      Marten::Template::Value.from(12).raw.should eq 12
      Marten::Template::Value.from(12_i64).raw.should eq 12_i64
    end

    it "is able to initialize a new value value from nil" do
      Marten::Template::Value.from(nil).raw.should be_nil
    end

    it "is able to initialize a new value value from a string" do
      Marten::Template::Value.from("foo bar").raw.should eq "foo bar"
    end

    it "is able to initialize a new value value from a time" do
      time = Time.local
      Marten::Template::Value.from(time).raw.should eq time
    end

    it "is able to initialize a new value value from a query set" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      value = Marten::Template::Value.from(Tag.all)

      value.raw.should be_a Marten::DB::Query::Set(Tag)
      value.raw.as(Marten::DB::Query::Set(Tag)).to_a.should eq [tag_1, tag_2, tag_3]
    end

    it "raises an unsupported value error if the passed value is not supported" do
      expect_raises(
        Marten::Template::Errors::UnsupportedValue,
        "Unable to initialize template values from Path objects"
      ) do
        Marten::Template::Value.from(Path["foo/bar/baz.cr"])
      end
    end
  end

  describe "#[]" do
    it "returns a value corresponding to the passed attribute for a hash" do
      value = Marten::Template::Value.from({"foo" => "bar", "test" => 42})

      value["foo"].should be_a Marten::Template::Value
      value["foo"].should eq Marten::Template::Value.from("bar")

      value["test"].should be_a Marten::Template::Value
      value["test"].should eq Marten::Template::Value.from(42)
    end

    it "returns a value corresponding to the passed index for an array" do
      value = Marten::Template::Value.from(["foo", "bar"])

      value["0"].should be_a Marten::Template::Value
      value["0"].should eq Marten::Template::Value.from("foo")

      value["1"].should be_a Marten::Template::Value
      value["1"].should eq Marten::Template::Value.from("bar")
    end

    it "returns a value corresponding to the passed index for a tuple" do
      value = Marten::Template::Value.from({"foo", "bar"})

      value["0"].should be_a Marten::Template::Value
      value["0"].should eq Marten::Template::Value.from("foo")

      value["1"].should be_a Marten::Template::Value
      value["1"].should eq Marten::Template::Value.from("bar")
    end

    it "returns a value corresponding to the passed attribute for a template object" do
      value = Marten::Template::Value.from(Marten::Template::ValueSpec::Test.new)

      value["test_attr"].should be_a Marten::Template::Value
      value["test_attr"].should eq Marten::Template::Value.from("hello")
    end

    it "raises an unknown variable error if the attribute does not exist" do
      value = Marten::Template::Value.from({"foo" => "bar", "test" => 42})
      expect_raises(Marten::Template::Errors::UnknownVariable) { value["unknown"] }
    end

    it "raises an unknown variable error if the index does not exist for an array" do
      value = Marten::Template::Value.from(["foo", "bar"])
      expect_raises(Marten::Template::Errors::UnknownVariable) { value["4"] }
    end

    it "raises an unknown variable error if the index is not a number for an array" do
      value = Marten::Template::Value.from(["foo", "bar"])
      expect_raises(Marten::Template::Errors::UnknownVariable) { value["bad"] }
    end

    it "raises an unknown variable error if the raw object does not allow attribute lookups" do
      value = Marten::Template::Value.from(42)
      expect_raises(Marten::Template::Errors::UnknownVariable) { value["unknown"] }
    end
  end

  describe "#==" do
    it "returns true if two value objects correspond to the same raw value" do
      (Marten::Template::Value.from(42) == Marten::Template::Value.from(42)).should be_true
    end

    it "returns true if a value object and another raw value correspond to the same raw value" do
      (Marten::Template::Value.from(42) == 42).should be_true
    end

    it "returns false if two value objects do not correspond to the same raw value" do
      (Marten::Template::Value.from(42) == Marten::Template::Value.from(11)).should be_false
    end

    it "returns true if a value object and another raw value do not corespond to the same raw value" do
      (Marten::Template::Value.from(42) == 11).should be_false
    end
  end

  describe "#<=>" do
    it "allows to compare number values" do
      (Marten::Template::Value.from(42) > Marten::Template::Value.from(4)).should be_true
      (Marten::Template::Value.from(42.12) > Marten::Template::Value.from(4)).should be_true
      (Marten::Template::Value.from(42) < Marten::Template::Value.from(100)).should be_true
      (Marten::Template::Value.from(42) > Marten::Template::Value.from(100)).should be_false
      (Marten::Template::Value.from(42.123) < Marten::Template::Value.from(100.121_2)).should be_true
    end

    it "raises an unsupported type exception of the underlying object is not comparable" do
      value = Marten::Template::Value.from("foo")
      expect_raises(
        Marten::Template::Errors::UnsupportedType,
        "Unable to compare String objects with Int32 objects"
      ) do
        value >= Marten::Template::Value.from(42)
      end
    end
  end

  describe "#each" do
    it "yields the keys of a specific hash" do
      value = Marten::Template::Value.from({"foo" => "bar", "test" => 42})

      arr = [] of Marten::Template::Value
      value.each { |v| arr << v }

      arr.size.should eq 2
      arr[0].should eq Marten::Template::Value.from(["foo", "bar"])
      arr[1].should eq Marten::Template::Value.from(["test", 42])
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

    it "yields the value of a specific query set" do
      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      value = Marten::Template::Value.from(Tag.all)

      arr = [] of Marten::Template::Value
      value.each { |v| arr << v }

      arr.size.should eq 3
      arr[0].should eq tag_1
      arr[1].should eq tag_2
      arr[2].should eq tag_3
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

  describe "#to_s" do
    it "returns the string representation of the underlying object" do
      Marten::Template::Value.from(42).to_s.should eq 42.to_s
      Marten::Template::Value.from("foo").to_s.should eq "foo".to_s
    end
  end

  describe "#truthy?" do
    it "returns false if the raw value is false" do
      Marten::Template::Value.from(false).truthy?.should be_false
    end

    it "returns false if the raw value is equal to 0" do
      Marten::Template::Value.from(0).truthy?.should be_false
    end

    it "returns false if the raw value is nil" do
      Marten::Template::Value.from(nil).truthy?.should be_false
    end

    it "returns true for an empty string" do
      Marten::Template::Value.from("").truthy?.should be_true
    end

    it "returns true for strings" do
      Marten::Template::Value.from("foo bar").truthy?.should be_true
    end

    it "returns true for other objects" do
      Marten::Template::Value.from(42).truthy?.should be_true
      Marten::Template::Value.from({"foo" => "bar", "test" => 42, "nested" => {"test" => 1}}).truthy?.should be_true
    end
  end
end

module Marten::Template::ValueSpec
  class Test
    include Marten::Template::Object::Auto

    def test_attr
      "hello"
    end
  end
end
