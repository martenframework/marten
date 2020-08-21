module Marten
  module DB
    abstract class Migration
      def apply
      end

      def unapply
      end
    end
  end
end
