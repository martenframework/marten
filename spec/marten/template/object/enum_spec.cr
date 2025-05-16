require "./spec_helper"

describe Marten::Template::Object::Enum do
  describe "#==" do
    it "returns true if the other enum corresponds to the same object" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.should eq enum_object
    end

    it "returns true if the other enum corresponds to the same enum object" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.should eq Marten::Template::Object::EnumSpec::Color::Blue
    end

    it "returns true if the other enum has the same properties" do
      enum_object_1 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )
      enum_object_2 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object_1.should eq enum_object_2
    end

    it "returns false if the other enum does not have the same class" do
      enum_object_1 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )
      enum_object_2 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::AltColor.name,
        enum_value_names: Marten::Template::Object::EnumSpec::AltColor.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::AltColor::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::AltColor::Blue.to_i64,
      )

      enum_object_1.should_not eq enum_object_2
    end

    it "returns false if the other enum does not have the same name" do
      enum_object_1 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )
      enum_object_2 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Red.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object_1.should_not eq enum_object_2
    end

    it "returns false if the other enum does not have the same value" do
      enum_object_1 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )
      enum_object_2 = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: 1_000.to_i64,
      )

      enum_object_1.should_not eq enum_object_2
    end

    it "returns false if the other enum does not correspond to the same enum object" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.should_not eq Marten::Template::Object::EnumSpec::Color::Red
    end
  end

  describe "#resolve_template_attribute" do
    it "returns true when the name? property is requested" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.resolve_template_attribute("blue?").should be_true
    end

    it "returns the name when requested" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.resolve_template_attribute("name").should eq Marten::Template::Object::EnumSpec::Color::Blue.to_s
    end

    it "returns the value when requested" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.resolve_template_attribute("value").should eq Marten::Template::Object::EnumSpec::Color::Blue.to_i64
    end

    it "returns false when the name? property is requested for another enum value" do
      enum_object = Marten::Template::Object::Enum.new(
        enum_class_name: Marten::Template::Object::EnumSpec::Color.name,
        enum_value_names: Marten::Template::Object::EnumSpec::Color.values.map(&.to_s),
        name: Marten::Template::Object::EnumSpec::Color::Blue.to_s,
        value: Marten::Template::Object::EnumSpec::Color::Blue.to_i64,
      )

      enum_object.resolve_template_attribute("red?").should be_false
      enum_object.resolve_template_attribute("green?").should be_false
    end
  end
end

module Marten::Template::Object::EnumSpec
  enum Color
    Red
    Green
    Blue
  end

  enum AltColor
    Red
    Green
    Blue
  end
end
