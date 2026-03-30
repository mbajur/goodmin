class Tag < ActiveRecord::Base
  belongs_to :comment, optional: true

  def to_s
    name
  end
end
