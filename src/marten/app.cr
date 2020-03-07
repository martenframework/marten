module Marten
  class App
    macro inherited
      @@location : String?

      def self.location
        @@location ||= Path[__FILE__].parent.to_s
      end
    end
  end
end
