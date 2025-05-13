# == Schema Information
#
# Table name: countries
#
#  id                  :integer          not null, primary key
#  name                :string
#  code                :string
#  name_without_accent :string
#
class Country < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :users

  # VALIDATIONS

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true #, uniqueness: true # Test database is broken if we impose uniqueness

end
