#this is a file to write random functions for one time modifications.

class HelperWorker
  include Sidekiq::Worker
  require 'scraper'
  require 'customdate'


  #worker for updating the daily % change column in the db. This process needs to be added to the scraper to be permanent.
  # def perform(ticker_symbol)
  #   stockprices = Stockprice.where(ticker_symbol:ticker_symbol).reorder("date Desc").limit(1501)
  #   case_lines = []
  #   stockprices[0..-2].each_with_index do |stockprice, index|
  #     previous_price = stockprices[index+1].close_price
  #     if previous_price == 0
  #       daily_percent_change = 0
  #     else
  #       daily_percent_change = ((stockprice.close_price/previous_price -1)*100).round(2)
  #     end
  #     case_lines << "WHEN date = '#{stockprice.date}' THEN #{daily_percent_change}"
  #   end
  #   unless case_lines.empty?
  #     sql = "update stockprices
  #             SET daily_percent_change = CASE
  #               #{case_lines.join("\n")}
  #             END
  #           WHERE ticker_symbol = '#{ticker_symbol}';" #this is the sql shell that runs. Its contents are based on its 2 arrays.
  #     ActiveRecord::Base.connection.execute(sql) #this executes the raw sql.
  #   end
  # end

  #this rounds all of the open and close price values to 2 decimals. Scraper has been updated.
  # def perform(ticker_symbol)
  #   stockprices = Intradayprice.where(ticker_symbol:ticker_symbol)
  #   case_line_opens = []
  #   case_line_closes = []
  #   stockprices.each do |stockprice|
  #     case_line_opens << "WHEN date = '#{stockprice.date}' THEN #{stockprice.open_price.round(2)}"
  #     case_line_closes << "WHEN date = '#{stockprice.date}' THEN #{stockprice.close_price.round(2)}"
  #   end

  #   unless case_line_opens == []
  #     sql = "update intradayprices
  #             SET open_price = CASE
  #               #{case_line_opens.join("\n")}
  #             END
  #           WHERE ticker_symbol = '#{ticker_symbol}';" #this is the sql shell that runs. Its contents are based on its 2 arrays.
  #     ActiveRecord::Base.connection.execute(sql) #this executes the raw sql.

  #     sql = "update intradayprices
  #             SET close_price = CASE
  #               #{case_line_closes.join("\n")}
  #             END
  #           WHERE ticker_symbol = '#{ticker_symbol}';" #this is the sql shell that runs. Its contents are based on its 2 arrays.
  #     ActiveRecord::Base.connection.execute(sql) #this executes the raw sql.
  #   end
  # end

  # def perform(ticker_symbol) #update the date string to be correct.
  #   stockprices = Stockprice.where(ticker_symbol:ticker_symbol)
  #   case_lines = []
  #   tz = ActiveSupport::TimeZone.new('America/New_York')

  #   unless stockprices.empty?

  #     stockprices.each do |stockprice|
        
  #       old_date = stockprice.date
  #       date_string = DateTime.strptime(old_date.to_s, "%Y-%m-%d")
  #       new_time_string = Time.parse(date_string.to_s) #convert the date format to a time format so that utc_time_full can be used.
  #       offset = tz.parse(new_time_string.to_s).utc_offset() #get the offset amount from EST. Could be 4 or 5 hours depending on DSt
  #       new_date = new_time_string - offset + 16*3600 #create the final adjusted UTC time.

  #       case_lines << "WHEN date = '#{stockprice.date}' THEN CAST('#{new_date}' AS timestamp)"
  #     end

  #     sql = "update stockprices
  #             SET date = CASE
  #               #{case_lines.join("\n")}
  #             END
  #           WHERE ticker_symbol = '#{ticker_symbol}';" #this is the sql shell that runs. Its contents are based on its 2 arrays.
  #     ActiveRecord::Base.connection.execute(sql) #this executes the raw sql.
  #   end
  # end


  # def perform(ticker_symbol) #update the graph_time in the daily table.


  #   tz = ActiveSupport::TimeZone.new('America/New_York')

  #   stockprices = Intradayprice.where(ticker_symbol:ticker_symbol)

  #   unless stockprices.empty?
  #     case_lines = []
  #     stockprices.each do |stockprice|
        
  #       old_date = stockprice.date
  #       graph_time = old_date.graph_time
        
  #       case_lines << "WHEN date = '#{stockprice.date}' THEN #{graph_time}"
  #     end

  #     sql = "update intradayprices
  #             SET graph_time = CASE
  #               #{case_lines.join("\n")}
  #             END
  #           WHERE ticker_symbol = '#{ticker_symbol}';" #this is the sql shell that runs. Its contents are based on its 2 arrays.
  #     ActiveRecord::Base.connection.execute(sql) #this executes the raw sql.
  #   end
  # end

  # def perform(ticker_symbol) #delete days including and after may 1st so they can be pulled correctly.
  #   stockprices = Stockprice.where(ticker_symbol:ticker_symbol).where("date >= ?", "2015-05-01 00:00:00 UTC")
  #   unless stockprices.empty?
  #     stockprices.each do |stockprice|
  #       stockprice.delete
  #     end
  #   end
  # end
  #     case_lines = []
  #     stockprices.each do |stockprice|

  def perform
    start_time = "2010-01-01 00:00:00".utc_time.graph_time
    inserts = []
    i = 1
    id_count = 0
    while i <= 1156896 #4017 * 24*60/5 = 1156896
      t = start_time + i*60*5*1000
      if t.valid_stock_time?
        date = t.utc_time
        now = Time.now.utc
        inserts.push "(#{id_count}, '#{now}', '#{now}', '#{date}', #{t})"
        id_count += 1
      end
      i += 1
    end
    sql = "INSERT INTO futuretimes (id, created_at, updated_at, time, graph_time) VALUES #{inserts.join(", ")}"
    ActiveRecord::Base.connection.execute sql
  end

end





