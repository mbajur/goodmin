require "goodmin/helpers/batch_actions"
require "goodmin/helpers/filters"
require "goodmin/helpers/tables"
require "goodmin/resources/resource_controller/batch_actions"

module Goodmin
  module Resources
    module ResourceController
      module Base
        extend ActiveSupport::Concern

        include BatchActions

        included do
          helper Goodmin::Helpers::BatchActions
          helper Goodmin::Helpers::Filters
          helper Goodmin::Helpers::Tables

          before_action :set_resource_service
          before_action :set_resource_class
          before_action :set_resource_parents
          before_action :set_resource, only: [:show, :new, :edit, :create, :update, :destroy]

          helper_method :resource_url_array, :resources_url_array, :new_button_visible?
        end

        def show
          respond_to do |format|
            format.html
            format.json
          end
        end

        def new; end

        def edit; end

        def create
          respond_to do |format|
            if @resource_service.create_resource(@resource)
              format.html { redirect_to redirect_after_create, notice: redirect_flash_message }
              format.json { render :show, status: :created, location: @resource }
            else
              format.html { render :edit }
              format.json { render json: @resource.errors, status: :unprocessable_entity }
            end
          end
        end

        def update
          respond_to do |format|
            if @resource_service.update_resource(@resource, resource_params)
              format.html { redirect_to redirect_after_update, notice: redirect_flash_message }
              format.json { render :show, status: :ok, location: @resource }
            else
              format.html { render :edit }
              format.json { render json: @resource.errors, status: :unprocessable_entity }
            end
          end
        end

        def destroy
          @resource_service.destroy_resource(@resource)

          respond_to do |format|
            format.html { redirect_to redirect_after_destroy, notice: redirect_flash_message }
            format.json { head :no_content }
          end
        end

        protected

        def set_resource_service
          @resource_service = resource_service
        end

        def set_resource_class
          @resource_class = resource_class
        end

        def set_resource_parents
          @resource_parents = resource_parents
        end

        def set_resource
          @resource = resource
          authorize(@resource) if authorization_enabled?
        end

        def resource_service_class
          resource_name = controller_path.split("/").last.singularize.classify
          "Goodmin::Resources::#{resource_name}Resource".constantize
        end

        def resource_service
          resource_service = resource_service_class.new

          if authentication_enabled?
            resource_service.options[:admin_user] = admin_user
          end

          if resource_parents.present?
            resource_service.options[:resource_parent] = resource_parents.last
          end

          resource_service
        end

        def resource_class
          @resource_service.resource_class
        end

        def resource_parents
          params.to_unsafe_h.each_with_object([]) do |(name, value), parents|
            if name =~ /(.+)_id$/
              parents << $1.classify.constantize.find(value)
            end
          end
        end

        def resource_params
          params.require(@resource_class.model_name.param_key.to_sym).permit(resource_params_defaults)
        end

        def resource_params_defaults
          defaults = @resource_service.attrs_for_form.map do |attribute|
            association = @resource_class.reflect_on_association(attribute.name)

            if association && association.macro == :belongs_to
              association.foreign_key.to_sym
            elsif association && nested_has_many_form?(attribute, association)
              { "#{attribute.name}_attributes".to_sym => nested_attribute_permit_list(association) }
            elsif association && (many_to_many_association?(association) || has_many_association?(association))
              { "#{attribute.name.to_s.singularize}_ids".to_sym => [] }
            elsif association && nested_attributes_accepted?(attribute.name)
              { "#{attribute.name}_attributes".to_sym => nested_attribute_permit_list(association) }
            elsif array_attribute?(attribute.name)
              { attribute.name => [] }
            else
              attribute.name
            end
          end

          defaults + @resource_service.class.additional_permitted_attributes(@resource)
        end

        def array_attribute?(attr_name)
          return false unless @resource_class.respond_to?(:attribute_types)

          attr_type = @resource_class.attribute_types[attr_name.to_s]
          serialized_array = (attr_type.respond_to?(:object_type) && attr_type.object_type == Array) ||
            (attr_type.respond_to?(:coder) && attr_type.coder.respond_to?(:object_class) && attr_type.coder.object_class == Array)
          native_array = if @resource_class.respond_to?(:column_for_attribute)
            column = @resource_class.column_for_attribute(attr_name)
            column.respond_to?(:array?) && column.array?
          else
            false
          end
          serialized_array || native_array
        end

        def nested_has_many_form?(attribute, association)
          attribute.field_class == Goodmin::Fields::NestedHasMany &&
            has_many_association?(association) &&
            nested_attributes_accepted?(attribute.name)
        end

        def nested_attributes_accepted?(attribute_name)
          @resource_class.method_defined?("#{attribute_name}_attributes=")
        end

        def nested_attribute_permit_list(association)
          service_class = Goodmin::ServiceLocator.find_service_class_for(association.klass, context_service_class: @resource_service.class)
          attrs = service_class&.attrs_for_form || []
          additional = service_class&.additional_permitted_attributes || []
          [:id, :_destroy] + attrs.map(&:name) + additional
        end

        def many_to_many_association?(association)
          association.macro == :has_and_belongs_to_many ||
            (association.macro == :has_many && association.options[:through].present?)
        end

        def has_many_association?(association)
          association.macro == :has_many && !association.options[:through].present?
        end

        def redirect_after_create
          redirect_after_save
        end

        def redirect_after_update
          redirect_after_save
        end

        def redirect_after_save
          resource_url_array
        end

        def redirect_after_destroy
          resources_url_array
        end

        def redirect_flash_message
          translate_scoped("flash.#{action_name}", resource: @resource.class.model_name.human)
        end
      end
    end
  end
end
