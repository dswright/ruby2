class StocksController < ApplicationController

	#Function to pull the whole stock file and then update all records.
	#Run daily
	#def create
	#	StocksWorker.perform_async
	#end

	def show
		#'current_stock' is defined in Stock Helper functions
		@stock = current_stock

		#Stock's posts, comments, and predictions to be shown in the view
		@posts = Stream.where(stock_id: @stock.id)
		@comments = Comment.where(ticker_symbol: @stock.ticker_symbol)
		@predictions = Prediction.where(stock_id: @stock.id)

		#creates comment variable to be used to set up the comment creation form (see app/views/shared folder)
    	@comment = Comment.new(ticker_symbol: @stock.ticker_symbol)

   		#creates comment variable to be used to set up the prediction creation form (see app/views/shared folder)
    	@prediction = Prediction.new(stock_id: @stock.id, prediction_score: 0) 	


    	gon.ticker_symbol = params[:ticker_symbol]

    	gon.price_array = Stock.get_historical_prices(params[:ticker_symbol])    

    	#this gets used by the view to generate the html buttons.

    	latest_utc_date = Stock.get_latest_date(gon.price_array)
    	@date_limits_array = Stock.create_x_date_limits(latest_utc_date)
	end

end
