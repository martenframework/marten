module Marten
  module DB
    abstract class Model
      module Comparison
        # Returns true if `other` is the exact same object or corresponds to the same record at the database level.
        def ==(other : self)
          super || !pk.nil? && other.pk == pk
        end

        # Allows to sort model instances based on primary keys.
        def <=>(other : self)
          return nil if pk.nil? || other.pk.nil?
          pk!.to_s <=> other.pk!.to_s
        end
      end
    end
  end
end
