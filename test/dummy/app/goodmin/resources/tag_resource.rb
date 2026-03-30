module Goodmin
  module Resources
    class TagResource
      include Goodmin::Resources::Resource

      index do
        attribute :id
        attribute :name
      end

      show do
        attribute :id
        attribute :name
      end

      form do
        attribute :name
      end
    end
  end
end
