class Document < ActiveRecord::Base
	include DocumentsHelper
	
	has_many :events

	# validate :must_be_valid_xml
	validate :must_be_valid_epidoc

	def must_be_valid_xml
		# errors.add_to_base("Content must be valid XML") unless (valid_xml?(content) != nil)
	end

	def must_be_valid_epidoc
		errors.add_to_base("Content must be valid EpiDoc") unless valid_epidoc?(content)
	end
end
