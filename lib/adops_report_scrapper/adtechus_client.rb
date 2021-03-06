require 'date'
require_relative 'base_client'

class AdopsReportScrapper::AdtechusClient < AdopsReportScrapper::BaseClient
  private

  def login
    @client.visit 'http://marketplace.adtechus.com'
    @client.fill_in 'Username', :with => @login
    begin
      @client.fill_in 'Password', :with => @secret
    rescue Exception => e
      puts 'You are selected in the Beta that sucks!!!'
      @client.find_all(:button).first.click
      sleep 10
      @client.fill_in 'Password', :with => @secret
    end
    @client.find_all(:button).first.click
    sleep 10
    begin
      @client.find :xpath, '//*[text()="REPORTING"]'
    rescue Exception => e
      raise e, 'Adtechus login error'
    end
  end

  def scrap
    request_report
  end

  def request_report
    @client.find(:xpath, '//*[text()="REPORTING"]').click
    wait_for_loading
    @client.visit(@client.find(:css, '#mainwindow')[:src])
    wait_for_loading
    report_id = @client.find_all(:xpath, '//tr[./td/div/span[text()="Placement fill rate report"]]')[-1][:id]
    report_id = report_id.tr 'row_', ''
    @client.visit "https://marketplace.adtechus.com/h2/reporting/showReport.do?action=showreportpage._._.#{report_id}"
    @client.within_frame @client.find(:css, '#reportwindow') do
      @client.within_frame @client.find(:xpath, '//iframe[@name="uid_2"]') do
        extract_data_from_report
      end
    end
  end

  def extract_data_from_report
    rows = @client.find_all :xpath, '//table[@class="table"]/tbody/tr'
    rows = rows.to_a
    rows.pop
    @data = rows.map { |tr| tr.find_css('td,th').map { |td| td.visible_text } }
  end

  def wait_for_loading
    18.times do |_i| # wait 3 min
      begin
        @client.find(:xpath, '//*[contains(text(),"loading")]')
      rescue Exception => e
        break
      end
      sleep 3
    end
    sleep 1
  end
end