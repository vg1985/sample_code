class JobDate
  include Mongoid::Document

  field :key, type: String
  field :date, type: DateTime
end