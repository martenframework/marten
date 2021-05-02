require "./spec_helper"

describe Marten::Template::Condition::Token::Operator::Infix do
  describe "#eval" do
    it "raises a not implemented error" do
      token = Marten::Template::Condition::Token::Operator::Infix.new
      expect_raises(
        NotImplementedError,
        "Should be implemented by subclasses"
      ) do
        token.eval(Marten::Template::Context{"foo" => "bar"})
      end
    end
  end

  describe "#id" do
    it "raises a not implemented error" do
      token = Marten::Template::Condition::Token::Operator::Infix.new
      expect_raises(
        NotImplementedError,
        "Should be implemented by subclasses"
      ) do
        token.id
      end
    end
  end

  describe "#lbp" do
    it "raises a not implemented error" do
      token = Marten::Template::Condition::Token::Operator::Infix.new
      expect_raises(
        NotImplementedError,
        "Should be implemented by subclasses"
      ) do
        token.lbp
      end
    end
  end

  describe "#led" do
    it "executes the infix handler" do
      condition = Marten::Template::Condition.new(["42", "||", "42"])

      token = Marten::Template::Condition::Token::Operator::InfixSpec::Test.new

      left = Marten::Template::Condition::Token::Value.new("'foo'")
      token.led(condition, left).should be token
      token.first.should be left
      token.second.should be_a Marten::Template::Condition::Token::Operator::Or
    end
  end
end

# ameba:disable Layout/LineLength
class Marten::Template::Condition::Token::Operator::InfixSpec::Test < Marten::Template::Condition::Token::Operator::Infix
  def lbp : UInt8
    2_u8
  end
end
