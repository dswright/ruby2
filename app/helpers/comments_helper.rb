module CommentsHelper

	def stock_or_user_page(stream)

		#If post was made on stock page, redirect to stock page
		if stream.targetable_type == "stock"
			stock = Stock.find_by(id: stream.targetable_id)
			"/stocks/#{stock.ticker_symbol}/"

		#If post was made on user page, redirect to user page
		elsif stream.targetable_type == "user"
			user = User.find_by(id: stream.targetable_id)
			"/users/#{user.username}/"
		end
	end

	def stock_or_user_view(stream)
		if stream.targetable_type == "stock"
			"/stocks/show"
		elsif stream.targetable_type == "user"
			"/users/show"
		end
	end
end

