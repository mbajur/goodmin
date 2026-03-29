require "test_helper"

module Goodmin
  class ResourceControllerParamsTest < ActiveSupport::TestCase
    # Minimal stubs used exclusively in this test
    module TestScope
      class ProfileResource
        include Goodmin::Resources::Resource

        form do
          attribute :bio
          attribute :website
        end
      end

      class Profile
        def self.name
          "Goodmin::ResourceControllerParamsTest::TestScope::Profile"
        end
      end

      class CommentResource
        include Goodmin::Resources::Resource

        form do
          attribute :title
          attribute :body
        end
      end

      class Comment
        def self.name
          "Goodmin::ResourceControllerParamsTest::TestScope::Comment"
        end
      end

      class Author
        # Simulates accepts_nested_attributes_for :profile
        def profile_attributes=(_attributes); end

        # Simulates accepts_nested_attributes_for :comments
        def comments_attributes=(_attributes); end

        def self.reflect_on_association(name)
          case name
          when :editor
            Struct.new(:macro, :foreign_key, :options, keyword_init: true).new(
              macro: :belongs_to, foreign_key: "editor_id", options: {}
            )
          when :profile
            Struct.new(:macro, :klass, :foreign_key, :name, :options, keyword_init: true).new(
              macro: :has_one, klass: Profile, foreign_key: nil, name: :profile, options: {}
            )
          when :comments
            Struct.new(:macro, :klass, :foreign_key, :name, :options, keyword_init: true).new(
              macro: :has_many, klass: Comment, foreign_key: nil, name: :comments, options: {}
            )
          end
        end
      end

      class AuthorResource
        include Goodmin::Resources::Resource

        form do
          attribute :name
          attribute :editor
          attribute :profile
          attribute :comments, as: Goodmin::Fields::NestedHasMany
        end
      end

      # A minimal controller object that exposes resource_params_defaults
      # without needing the full ActionController stack.
      class FakeController
        # Stub ActionController class-level methods used in included blocks
        def self.helper(*) end
        def self.before_action(*) end
        def self.prepend_before_action(*) end
        def self.helper_method(*) end

        include Goodmin::Resources::ResourceController

        # Expose the protected methods for testing
        public :resource_params_defaults

        def initialize(resource_class, resource_service)
          @resource_class = resource_class
          @resource_service = resource_service
        end
      end
    end

    def setup
      @controller = TestScope::FakeController.new(
        TestScope::Author,
        TestScope::AuthorResource.new
      )
    end

    def test_plain_attributes_are_permitted
      params = @controller.resource_params_defaults
      assert_includes params, :name
    end

    def test_belongs_to_association_uses_foreign_key
      params = @controller.resource_params_defaults
      assert_includes params, :editor_id
      assert_not_includes params, :editor
    end

    def test_nested_has_one_attributes_are_permitted
      params = @controller.resource_params_defaults
      nested_entry = params.find { |p| p.is_a?(Hash) && p.key?(:profile_attributes) }
      assert nested_entry, "Expected profile_attributes key in permitted params"
      assert_includes nested_entry[:profile_attributes], :id
      assert_includes nested_entry[:profile_attributes], :bio
      assert_includes nested_entry[:profile_attributes], :website
    end

    def test_nested_has_many_attributes_are_permitted
      params = @controller.resource_params_defaults
      nested_entry = params.find { |p| p.is_a?(Hash) && p.key?(:comments_attributes) }
      assert nested_entry, "Expected comments_attributes key in permitted params"
      assert_includes nested_entry[:comments_attributes], :id
      assert_includes nested_entry[:comments_attributes], :_destroy
      assert_includes nested_entry[:comments_attributes], :title
      assert_includes nested_entry[:comments_attributes], :body
    end

    def test_nested_has_many_does_not_use_ids_param
      params = @controller.resource_params_defaults
      ids_entry = params.find { |p| p.is_a?(Hash) && p.key?(:comment_ids) }
      assert_nil ids_entry, "Expected no comment_ids key when nested attributes are accepted"
    end

    def test_additional_permitted_attributes_are_included
      resource_class = Class.new do
        def self.name; "FakeModel"; end
        def self.reflect_on_association(_); nil; end
        def self.attribute_types; {}; end
      end
      resource_service_class = Class.new do
        include Goodmin::Resources::Resource
        form { attribute :title }

        def self.additional_permitted_attributes(record = nil)
          [:extra_token, :internal_flag]
        end
      end
      controller = TestScope::FakeController.new(resource_class, resource_service_class.new)

      params = controller.resource_params_defaults
      assert_includes params, :extra_token
      assert_includes params, :internal_flag
    end

    def test_additional_permitted_attributes_receives_record
      resource_class = Class.new do
        def self.name; "FakeModel"; end
        def self.reflect_on_association(_); nil; end
        def self.attribute_types; {}; end
      end
      received_record = nil
      resource_service_class = Class.new do
        include Goodmin::Resources::Resource
        form { attribute :title }

        define_singleton_method(:additional_permitted_attributes) do |record = nil|
          received_record = record
          []
        end
      end
      fake_record = Object.new
      controller = TestScope::FakeController.new(resource_class, resource_service_class.new)
      controller.instance_variable_set(:@resource, fake_record)

      controller.resource_params_defaults
      assert_equal fake_record, received_record, "Expected record to be passed to additional_permitted_attributes"
    end

    def test_additional_permitted_attributes_injected_into_nested_permit_list
      resource_class_with_additional = Class.new do
        include Goodmin::Resources::Resource
        form { attribute :note }

        def self.additional_permitted_attributes(record = nil)
          [:metadata]
        end
      end
      # Give it a name so ServiceLocator can find it
      resource_class_with_additional.define_singleton_method(:name) do
        "Goodmin::ResourceControllerParamsTest::TestScope::Comment"
      end

      # Temporarily override ServiceLocator to return our class
      original_method = Goodmin::ServiceLocator.method(:find_service_class_for)
      Goodmin::ServiceLocator.define_singleton_method(:find_service_class_for) do |*_args|
        resource_class_with_additional
      end

      begin
        params = @controller.resource_params_defaults
        nested_entry = params.find { |p| p.is_a?(Hash) && p.key?(:comments_attributes) }
        assert nested_entry, "Expected comments_attributes in permitted params"
        assert_includes nested_entry[:comments_attributes], :metadata
      ensure
        Goodmin::ServiceLocator.define_singleton_method(:find_service_class_for, &original_method)
      end
    end

    def test_serialized_array_attribute_is_permitted_as_array
      article_resource = Class.new do
        include Goodmin::Resources::Resource
        form { attribute :properties }
      end
      controller = TestScope::FakeController.new(Article, article_resource.new)

      params = controller.resource_params_defaults
      array_entry = params.find { |p| p.is_a?(Hash) && p.key?(:properties) }
      assert array_entry, "Expected properties to be permitted as an array"
      assert_equal [], array_entry[:properties]
    end

    def test_native_array_column_attribute_is_permitted_as_array
      post_class = Class.new do
        def self.name; "Post"; end
        def self.reflect_on_association(_); nil; end
        def self.attribute_types; { "tags" => Object.new }; end
        def self.column_for_attribute(_attr); Struct.new(:array?).new(true); end
      end
      post_resource = Class.new do
        include Goodmin::Resources::Resource
        form { attribute :tags }
      end
      controller = TestScope::FakeController.new(post_class, post_resource.new)

      params = controller.resource_params_defaults
      array_entry = params.find { |p| p.is_a?(Hash) && p.key?(:tags) }
      assert array_entry, "Expected tags to be permitted as an array"
      assert_equal [], array_entry[:tags]
    end
  end
end
