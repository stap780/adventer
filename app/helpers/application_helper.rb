module ApplicationHelper
    def wicked_image_active_storage_workaround( image )
        if image.is_a? ActiveStorage::Attachment
          save_path = Rails.root.join( "public/tmp/pdf", "#{image.id}.#{image.filename.to_s.split('.').last}")
          File.open(save_path, 'wb') do |file|
            file << image.blob.download
          end
          return save_path.to_s
    
        elsif image.is_a? ActiveStorage::Attached
          save_path = Rails.root.join( "public/tmp/pdf", "#{image.id}.#{image.filename.to_s.split('.').last}")
          File.open(save_path, 'wb') do |file|
            file << image.blob.download
          end
          return save_path.to_s
          
        end
      end


end
