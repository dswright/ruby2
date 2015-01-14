class StocksController < ApplicationController
require 'stockgraph'

	#Function to pull the whole stock file and then update all records.
	#Run daily
	#def create
	#	StocksWorker.perform_async
	#end

	def show

    stock_id = Stock.find_by(ticker_symbol:params[:ticker_symbol])
    @ticker_symbol = params[:ticker_symbol]

		@current_user = current_user
		@stock = Stock.find(stock_id)
		#Stock's posts, comments, and predictions to be shown in the view
		streams = Stream.where(target_type: "Stock", target_id: @stock.id)
    @stream_hash_array = Stream.stream_maker(streams, 0)

    #if a stock gets viewed, update the stocks table so that the stock gets real time stock data.
    if (@stock.viewed == false)
      @stock.viewed = true
      @stock.save
      IntradayWorker.perform_async(@ticker_symbol, 5)
    end

		#creates comment variable to be used to set up the comment creation form (see app/views/shared folder)
  	@comment = Comment.new
    @like = Like.new

 		#creates comment variable to be used to set up the prediction creation form (see app/views/shared folder)
  	@prediction = Prediction.new(score: 0, active: 1, start_price: @stock.daily_stock_price) 	

  	@comment_stream_inputs = "Stock:#{@stock.id}"
  	@prediction_stream_inputs = "Stock:#{@stock.id}"

    @prediction_landing_page = "stocks:#{@stock.ticker_symbol}"
    @comment_landing_page = "stocks:#{@stock.ticker_symbol}"
    @stream_comment_landing_page = "stocks:#{@stock.ticker_symbol}"

  	gon.ticker_symbol = @ticker_symbol
  	gon.daily_price_array = StockGraph.get_daily_price_array(@ticker_symbol)    

    gon.intraday_price_array = StockGraph.get_intraday_price_array(@ticker_symbol) 

    gon.intraday_forward_array = StockGraph.intraday_forward_array(gon.intraday_price_array.last[0])  #this end of time needs to be defined. THen this array will work. 
    #may need to store this array in the loops?? Not sure how to get the end_time variable in here, and also not sure how to load the 2
    #different looking foward arrays... Just load both. Each needs it's own definition function.

  	#this gets used by the view to generate the html buttons.
  	@date_limits_array = StockGraphPublic.create_x_date_limits(gon.daily_price_array, gon.intraday_price_array)

    gon.graph_default_x_range_min = @date_limits_array[2][:x_range_min] #the 1 month settings
    gon.graph_default_x_range_max = @date_limits_array[2][:x_range_max] #the 1 month settings
    gon.graph_default_y_range_min = @date_limits_array[2][:y_range_min] #the 1 month settings

    gon.prediction_points_array = Prediction.graph_prediction_points(stock_id)
	end
end
