module Goodmin
  module Fields
    class NestedHasMany < BaseNested

      def associated_records
        record.public_send(attribute)
      end

      def new_record
        @new_record ||= associated_model_class&.new
      end

      def associated_service
        @associated_service ||= associated_service_class&.new
      end

      def nested_form_nodes
        associated_service&.form_nodes || []
      end

      def show_destroy_button?
        options.fetch(:allow_destroy, true)
      end

      def show_add_new_button?
        options.fetch(:allow_add_new, true)
      end

      protected

      def nested_record_instance
        new_record
      end

      private

      def reflection
        record.class.reflect_on_association(attribute)
      end

      def associated_model_class
        reflection&.klass
      end
    end
  end
end
