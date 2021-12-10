require "./template"

module Marten
  module Views
    # View allowing to list model records.
    class RecordList < Template
      # Returns the configured model class.
      class_getter model : DB::Model.class | Nil

      # Returns the queryset used to retrieve the record displayed by the view.
      def queryset
        self.class.model.not_nil!.all
      end
    end
  end
end
