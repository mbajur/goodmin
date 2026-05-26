require "test_helper"

module Goodmin
  class NestedHasManyFieldTest < ActiveSupport::TestCase
    # Minimal fake models and resources used exclusively in this test
    module TestScope
      class CommentResource
        include Goodmin::Resources::Resource

        form do
          attribute :title
          attribute :body
        end
      end

      class Comment
        def self.name
          "Goodmin::NestedHasManyFieldTest::TestScope::Comment"
        end

        def self.new
          super
        end

        def to_s
          "Comment"
        end
      end

      class Article
        def self.reflect_on_association(name)
          return nil unless name == :comments

          Struct.new(:klass, :macro).new(Comment, :has_many)
        end

        def comments
          @comments ||= []
        end
      end

      class ArticleResource
        include Goodmin::Resources::Resource
      end
    end

    def setup
      @record = TestScope::Article.new
      @resource_service = TestScope::ArticleResource.new
      @field = Fields::NestedHasMany.new(
        attribute: :comments,
        record: @record,
        resource_service: @resource_service
      )
    end

    def test_associated_records_returns_collection
      assert_equal @record.comments, @field.associated_records
    end

    def test_new_record_returns_new_model_instance
      assert_instance_of TestScope::Comment, @field.new_record
    end

    def test_new_record_is_memoized
      assert_same @field.new_record, @field.new_record
    end

    def test_associated_service_finds_service_by_convention
      assert_instance_of TestScope::CommentResource, @field.associated_service
    end

    def test_nested_form_nodes_returns_empty_when_no_service
      field = Fields::NestedHasMany.new(
        attribute: :missing,
        record: TestScope::Article.new,
        resource_service: @resource_service
      )
      assert_equal [], field.nested_form_nodes
    end

    def test_partial_paths
      assert_equal "goodmin/fields/nested_has_many/form", Fields::NestedHasMany.partial_form
      assert_equal "goodmin/fields/nested_has_many/index", Fields::NestedHasMany.partial_index
      assert_equal "goodmin/fields/nested_has_many/show", Fields::NestedHasMany.partial_show
    end

    def test_resource_class_option_overrides_associated_service
      custom_resource = Class.new do
        include Goodmin::Resources::Resource
      end

      field = Fields::NestedHasMany.new(
        attribute: :comments,
        record: @record,
        resource_service: @resource_service,
        resource_class: custom_resource
      )
      assert_instance_of custom_resource, field.associated_service
    end

    def test_show_destroy_button_is_enabled_by_default
      assert @field.show_destroy_button?
    end

    def test_show_destroy_button_can_be_disabled_with_allow_destroy
      field = Fields::NestedHasMany.new(
        attribute: :comments,
        record: @record,
        resource_service: @resource_service,
        allow_destroy: false
      )

      refute field.show_destroy_button?
    end

    def test_show_destroy_button_can_be_enabled_with_allow_destroy
      field = Fields::NestedHasMany.new(
        attribute: :comments,
        record: @record,
        resource_service: @resource_service,
        allow_destroy: true
      )

      assert field.show_destroy_button?
    end

    def test_show_add_new_button_is_enabled_by_default
      assert @field.show_add_new_button?
    end

    def test_show_add_new_button_can_be_disabled_with_allow_add_new
      field = Fields::NestedHasMany.new(
        attribute: :comments,
        record: @record,
        resource_service: @resource_service,
        allow_add_new: false
      )

      refute field.show_add_new_button?
    end

    def test_show_add_new_button_can_be_enabled_with_allow_add_new
      field = Fields::NestedHasMany.new(
        attribute: :comments,
        record: @record,
        resource_service: @resource_service,
        allow_add_new: true
      )

      assert field.show_add_new_button?
    end
  end
end
