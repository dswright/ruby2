module StreamsHelper


  #used to display each stream object in the stream.
  def stream_redirect_processor(landing_page)
    landing_page_elements = landing_page.split(":")
    return "/#{landing_page_elements[0]}/#{landing_page_elements[1]}/"
  end

  def response_maker(msgs)
    html = ""
    if msgs
      msgs.each do |msg|
        html += html + "<li>" + msg + "</li>";
      end
    end
    return html
  end

 
  
  def sort_by_popularity(streams)

    #Build an array of comments and prediction id/popularity_score hashes
    popularity_ranking = popularity_array(streams)

    sorted_streams = []
    popularity_ranking.each do |ranking|
      stream = Stream.find(ranking[:id])
      sorted_streams << stream
    end

    return sorted_streams

  end

  def popularity_array(streams)
    popularity_array = []

    streams.each do |stream| 
      target = stream.streamable
      target_rank = { id: stream.id, popularity_score: target.popularity.score }
      popularity_array << target_rank
    end

    #Sort by popularity score ranking
    popularity_array = popularity_array.sort_by {|stream| stream[:popularity_score]}

    return popularity_array
  end

  def tweet_link(prediction)
    url = "https://twitter.com/intent/tweet?"

    tweet = {
      hashtags: "stockiq"
    }

    tweet[:text] = html_escape("#{prediction.stock.ticker_symbol} stock will go up to #{number_to_currency(prediction.prediction_end_price)} in #{time_ago_in_words(prediction.prediction_end_time)}").gsub(/\s+/,"%20")
    #tweet[:text] = URI.endcode("#{prediction.stock.ticker_symbol} stock will go up to #{number_to_currency(prediction.prediction_end_price)} in time_ago_in_words(prediction.prediction_end_time) ##{tweet[:hash_tag]}")
    extension = tweet.map { |k, v| "#{k}=#{v}" }.join("&")

    return url + extension
  end

end
