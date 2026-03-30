class Comment < ActiveRecord::Base
  belongs_to :article, optional: true
  has_many :tags

  def to_s
    title
  end
end
