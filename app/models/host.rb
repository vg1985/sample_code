require 'resolv'
class Host < ActiveRecord::Base

  ## VALIDATIONS ##
  validates :host_ip, :subnet, :port, presence: true
  validates :host_ip, format: { with: Resolv::IPv4::Regex, allow_blank: true }
  validates :subnet, inclusion: { in: 0..32, allow_blank: true }
  validates :port, inclusion: { in: 0..65535, allow_blank: true }
  validates :port, uniqueness: { scope: [:subnet, :host_ip, :trunk_type], allow_blank: true }

  ## ASSOCIATIONS ##
  belongs_to :trunk, polymorphic: true
end
