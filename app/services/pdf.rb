#  это работает и быстро создаёт . Но надо сделать чтобы футер всегда был внизу. Сейчас я из одного файла создаю. Надо подумать как создавать из двух html  (по типу как сделано в контроллере)
class Services::Pdf

    def initialize(kp, options={})
        @kp = kp
        @our_company = @kp.order.companykp1
    end

    def call
        save_path_html = Rails.root.join('public/pdfs','test_serv.html')
        html = ActionController::Base.new.render_to_string(template: 'kps/test_print.html.erb', locals: {:@kp=> @kp, :@our_company => @our_company})
        File.open(save_path_html, 'wb') do |file|
            file << html
        end
        html_file = "/Users/administrator/Documents/rails_projects/adventer/public/pdfs/test_serv.html"
        # pdf = WickedPdf.new.pdf_from_html_file('file:///Users/administrator/Documents/rails_projects/adventer/public/pdfs/test.html')
        pdf = WickedPdf.new.pdf_from_html_file(html_file)
        save_path_pdf = Rails.root.join('public/pdfs','test_serv.pdf')
        File.open(save_path_pdf, 'wb') do |file|
            file << pdf
        end
    end


end