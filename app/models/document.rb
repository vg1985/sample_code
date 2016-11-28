class Document < ActiveRecord::Base
	has_attached_file :content
	belongs_to :documentable, polymorphic: true
	belongs_to :user

	validates_attachment_presence :content
	validates_attachment_content_type :content, :content_type => [ /\Aimage\/.*\Z/, /\Aapplication\/pdf\Z/ ], message: "File content type is invalid."
  	validates_attachment_size :content, :in => 0..5.megabytes, message: "File size exceeds the allowed limit of 5 MB"
end
