class Device
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::MassAssignmentSecurity

  field :key_handle
  field :certificate
  field :public_key
  field :counter

  index key_handle: 1
end
