module KpsHelper

  def kp_status_bg_color(status)
    # puts status
    background_class = 'bg-dark text-white text-center' if status.include?('Новый')
    background_class = 'bg-info text-dark text-center' if status.include?('В работе')
    background_class = 'bg-warning text-dark text-center' if status.include?('Ждёт печати')
    background_class = 'bg-success text-white text-center' if status.include?('Финальный')
    return background_class.to_s
  end

  def kp_status_button(status)
    # puts status
    button_class = 'btn btn-outline-secondary btn-sm' if status.include?('Новый')
    button_class = 'btn btn-outline-secondary btn-sm' if status.include?('В работе')
    button_class = 'btn btn-outline-secondary btn-sm' if status.include?('Ждёт печати')
    button_class = 'btn btn-outline-light btn-sm' if status.include?('Финальный')
    return button_class.to_s
  end

end
