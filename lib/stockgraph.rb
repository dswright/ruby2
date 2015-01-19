class StockGraph
  require 'customdate'
 
  def self.return_date_based_on_days(last_utc_date, days)
    last_utc_date + (days*60*60*24*1000)
  end

  def self.find_y_min(price_array, start_time, end_time, prediction_array)
    #creates array out of the time and prices that are within the date limits
    limited_array = price_array.select{|price| price[0] >= start_time && price[0]<=end_time}
    limited_prediction_array = prediction_array.select{|prediction| prediction[0] >= start_time && prediction[0]<=end_time}
    min_price_array = limited_array.min_by {|item| item[1]}
    min_price = min_price_array[1]
    min_price_final = min_price
    limited_prediction_array.each do |prediction|
      if prediction[1] < min_price
        if prediction[1] > min_price * 0.7 #if the min price is 300, the min prediction is 210.
          min_price_final = prediction[1] * 0.95
        end
      end
    end
    return min_price_final
  end

  def self.find_y_max(price_array, start_time, end_time, prediction_array)
    limited_array = price_array.select{|price| price[0] >= start_time && price[0]<=end_time}
    limited_prediction_array = prediction_array.select{|prediction| prediction[0] >= start_time && prediction[0]<=end_time}
    max_price_array = limited_array.max_by {|item| item[1]}
    max_price = max_price_array[1]
    max_price_final = max_price
    limited_prediction_array.each do |prediction|
      if prediction[1] > max_price
        if prediction[1] < max_price * 1.3 #if the preidction price is 300, but stock must at least go down to 450 for the prediction to show.
          max_price_final = prediction[1] * 1.05
        end
      end
    end
    return max_price_final
  end

  def self.graph_prediction_points(stock_id)  
    graph_array = []
    prediction_array = Prediction.where(stock_id:stock_id).limit(1500).order('end_time asc')
    prediction_array.each do |prediction|
      utc_date_number = CustomDate.utc_date_string_to_utc_date_number(prediction.end_time) - 5*3600*24 #reduce db time by 5 hours to get to est.
      graph_array << [utc_date_number, prediction.prediction_price]
    end
    return graph_array
  end

  #this function forms a full 5 year array. The actual control is done with the x axis settings of the graph.
  def self.get_daily_price_array(ticker_symbol)
  stock_prices = Stockprice.where(ticker_symbol:ticker_symbol).limit(1500).order('date asc')    
    price_array = []
    stock_prices.each do |price|
      utc_time = CustomDate.utc_date_string_to_utc_date_number(price.date) - 5*3600*1000 #get into est
      price_array << [utc_time, price.close_price]
    end
    return price_array
  end

  def self.get_intraday_price_array(ticker_symbol)
  stock_prices = Intradayprice.where(ticker_symbol:ticker_symbol).limit(400).order('date asc')    
  price_array = []
    unless stock_prices.empty?
      stock_prices.each do |price|
        utc_time = CustomDate.utc_date_string_to_utc_date_number(price.date) - 5*3600*1000 #get into est
        price_array << [utc_time, price.close_price]
      end
      return price_array
    end
  end

  def self.daily_forward_array(end_time)
    #to be defined. Check on.. the backwards looking array first.
    i = 1;
    forward_array = []
    iterations = 602  #600 days is the maximum look-forward period for the x axis setting.
    while i<=iterations do
      time_spot = end_time + i*24*3600*1000 - 5*3600*1000 #subtract 5 hours to get the end of day range into valid date time.
      if CustomDate.check_if_out_of_time(time_spot)
        iterations += 1
      else
        forward_array << [time_spot+5*3600*1000, nil]
      end
      i += 1
    end
    return forward_array
  end
  


  def self.intraday_forward_array(end_time)
    #returns an array of time time and price variables.
    #used to look into the future on the graph.
    #intraday forward array currently looks ahead 3 days arbitrarily. 
    #The actual target setting is controlled with the x axis settings.
    i = 0;
    forward_array = []
    iterations = (3*3600*6.5)/(5*60) + 2 #the 1000 is not here because it gets divided out.
    #total time divided by 5 minutes to get total 5 minute itterations. 
    #6.5 hours used because that is how long the market is open for.
    while i<=iterations do
      time_spot = end_time + i*5*60*1000
      if CustomDate.check_if_out_of_time(time_spot)
        iterations += 1
      else
        forward_array << [time_spot, nil]
      end
      i += 1
    end
    return forward_array
  end

end

class StockGraphPublic
  def self.create_x_date_limits(daily_array, intraday_array, prediction_array)
    last_utc_date_daily = daily_array.last[0]
    last_utc_date_intraday = intraday_array.last[0]
    array_details_intraday = [{name:"1d", start:1, finish:0.5}, #
                     {name:"5d", start:5, finish:2.5}] #finish will adjust the end time used on the x axis. 
                     #The date_forward_array will always be set to 3 days ahead, so setting this value to more than 3 days
                     #will have minimal affect.

    array_details_daily = [{name:"1m", start:20, finish:10},
                     {name:"3m", start:60, finish:30},
                     {name:"6m", start:120, finish:60},
                     {name:"1yr", start:240, finish:120},
                     {name:"5yr", start:1200, finish:600}]

    date_hash_array = []

    array_details_intraday.each do |detail|
      start_time = CustomDate.valid_start_point(last_utc_date_intraday,  60*5*1000, detail[:start]*6.5*3600*1000)
      end_time = CustomDate.valid_end_point(last_utc_date_intraday, 60*5*1000, detail[:finish]*6.5*3600*1000)

      date_hash_array << {name: detail[:name],
                          x_range_min:start_time, 
                          x_range_max:end_time,
                          y_range_min:StockGraph.find_y_min(intraday_array, start_time, end_time, prediction_array),
                          y_range_max:StockGraph.find_y_max(intraday_array, start_time, end_time, prediction_array)
                        }
    end

    #The utc daily date get 5 hours subtracted to put them in valid range for the day the end time occurs.
    array_details_daily.each do |detail|
      start_time = CustomDate.valid_start_point(last_utc_date_daily-(5*3600*1000), 24*3600*1000, detail[:start]*24*3600*1000)
      end_time = CustomDate.valid_end_point(last_utc_date_daily-(5*3600*1000), 24*3600*1000, detail[:finish]*24*3600*1000)
      date_hash_array << {name: detail[:name], 
                          x_range_min:start_time, 
                          x_range_max:end_time,
                          y_range_min:StockGraph.find_y_min(daily_array, start_time, end_time, prediction_array),
                          y_range_max:StockGraph.find_y_max(daily_array, start_time, end_time, prediction_array)
                        }
    end
    return date_hash_array
  end
end