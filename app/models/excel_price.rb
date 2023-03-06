class ExcelPrice < ApplicationRecord
    before_save :normalize_data_white_space
    before_create :set_file_status_for_new_obj
    
    validates :title, presence: true




    private
    
    def normalize_data_white_space
        self.attributes.each do |key, value|
            self[key] = value.squish if value.respond_to?("squish")
        end
    end

    def set_file_status_for_new_obj
        self.file_status = 'not start'
    end


end
