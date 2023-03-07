module KpsHelper

  def kp_status_bg_color(status)
    # puts status
    background_class = 'bg-dark text-white text-center' if status.include?('Новый')
    background_class = 'bg-info text-dark text-center' if status.include?('В работе')
    background_class = 'bg-warning text-dark text-center' if status.include?('Ждёт печати')
    background_class = 'bg-success text-white text-center' if status.include?('Финальный')
    return background_class.to_s
  end

end
