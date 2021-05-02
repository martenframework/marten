require "./spec_helper"

describe Marten::Template::Condition::Token::Operator::Prefix do
  describe "#eval" do
    it "raises a not implemented error" do
      token = Marten::Template::Condition::Token::Operator::Prefix.new
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
      token = Marten::Template::Condition::Token::Operator::Prefix.new
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
      token = Marten::Template::Condition::Token::Operator::Prefix.new
      expect_raises(
        NotImplementedError,
        "Should be implemented by subclasses"
      ) do
        token.lbp
      end
    end
  end

  describe "#nud" do
    it "executes the prefix handler" do
      condition = Marten::Template::Condition.new(["42", "||", "42"])

      token = Marten::Template::Condition::Token::Operator::PrefixSpec::Test.new
      token.nud(condition).should be token
      token.first.should be_a Marten::Template::Condition::Token::Operator::Or
    end
  end
end

# ameba:disable Layout/LineLength
class Marten::Template::Condition::Token::Operator::PrefixSpec::Test < Marten::Template::Condition::Token::Operator::Prefix
  def lbp : UInt8
    2_u8
  end
end
