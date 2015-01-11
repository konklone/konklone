class Device
  include Mongoid::Document
  include Mongoid::Timestamps

  field :key_handle
  field :certificate
  field :public_key
  field :counter
  field :name # U2F doesn't ask for this, but I do

  validates_presence_of :key_handle
  validates_presence_of :certificate
  validates_presence_of :public_key
  validates_presence_of :counter
  validates_presence_of :name

  index key_handle: 1
end
