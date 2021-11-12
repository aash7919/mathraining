#encoding: utf-8

# == Schema Information
#
# Table name: discussions
#
#  id           :integer          not null, primary key
#  last_message :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Discussion < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :links, dependent: :destroy
  has_many :users, through: :links
  has_many :tchatmessages, dependent: :destroy

end
