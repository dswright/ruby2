class CommentsController < ApplicationController

	def create
		#Obtain user session information from Session Helper function 'current_user'.
		@user = current_user
		stock = Stock.find_by(ticker_symbol: params[:ticker_symbol])

		#build the comment for input to the db.
		comment = @user.comments.build(comment_params)
		
		#Add ticker_symbol to content and find '$' and '@' handles in comment content
		comment.add_tags(stock.ticker_symbol)

		response_msgs = []
		if comment.valid?
			comment.save

			#Initialize comment's popularity score in Popularity model
			comment.build_popularity(score:0).save #build the popularity score table item.

			#Build stream items targeting stock and current user
			comment.streams.create(targetable_id: stock.id, targetable_type: stock.class.name)
			comment.streams.create(targetable_id: @user.id, targetable_type: @user.class.name)

			
			@streams = [Stream.where(streamable_type: 'Comment', streamable_id: comment.id).first] #get this one stream item.
			response_msgs << "Comment added!" #gets inserted at top of page with ajax.
		else
			response_msgs << "Comment invalid." #gets inserted at top of page with ajax.
		end
		
		@response = response_maker(response_msgs)

		respond_to do |f|
			f.js
		end
	end

	private
		def comment_params
			#Obtains parameters from 'comment form' in app/views/shared.
			#Permits adjustment of only the 'content' column in the 'comments' model.
			params.require(:comment).permit(:content)
		end
end
