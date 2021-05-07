require "./spec_helper"

describe Marten::Template::Condition::Token::Operator::In do
  describe "#eval" do
    it "applies the in operator as expected" do
      condition = Marten::Template::Condition.new(["var2"])

      token = Marten::Template::Condition::Token::Operator::In.new
      token.led(condition, Marten::Template::Condition::Token::Value.new("var1"))

      token.eval(Marten::Template::Context{"var1" => "foo", "var2" => ["foo", "bar"]}).truthy?.should be_true
      token.eval(Marten::Template::Context{"var1" => 42, "var2" => [1, 2, 42, 5]}).truthy?.should be_true
      token.eval(Marten::Template::Context{"var1" => "test", "var2" => ["foo", "bar"]}).truthy?.should be_false
      token.eval(Marten::Template::Context{"var1" => 12, "var2" => [1, 2, 42, 5]}).truthy?.should be_false
    end
  end

  describe "#id" do
    it "returns the expected identified" do
      Marten::Template::Condition::Token::Operator::In.new.id.should eq "in"
    end
  end

  describe "#lbp" do
    it "returns the expected left binding power" do
      Marten::Template::Condition::Token::Operator::In.new.lbp.should eq 9_u8
    end
  end
end
