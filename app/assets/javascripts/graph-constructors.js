function BuildStockGraph(defaults, graphName) {
  this.launch = function() {
    graphMediator.addComponents('defaults', defaults);
    graphMediator.defaultProcessor(); //creates several default components automatically for every graph.

    graphMediator.createPredictionLine("daily", "predictions"); //create this predictions graph line for the stock graph only.
    graphMediator.createPredictionLine("intraday", "predictions"); //create this predictions graph line for the stock graph only.

    graphMediator.createPredictionLine("daily", "myPrediction"); //create this predictions graph line for the stock graph only.
    graphMediator.createPredictionLine("intraday", "myPrediction"); //create this predictions graph line for the stock graph only.

    graphMediator.removeOverlapping("intraday", "myPrediction");
    graphMediator.removeOverlapping("daily", "myPrediction");

    var currentFrame = {
      framesHash: graphMediator.framesHash("stockGraph")
    };
    graphMediator.addComponents('currentFrame', currentFrame); //currentframe must be used before setRange is used.

    var bestRange = graphMediator.bestRange("myPrediction");
    graphMediator.updateComponent("currentFrame", function(component) {
      this.timeFrame = bestRange;
    });

    // sets the daily or intraday lines, depending on the timeFrame in the currentFrame. Also sets the hover state.
    graphMediator.frameDependents("stockGraph");

    // the timeFrame in the currentFrame component must be set before using this. 
    graphMediator.setRange();
  }

  this.buttonClick = function() {
    var buttonType = $(this).data("button-type");
    var callback = function(component) { this.timeFrame = buttonType }; //the cb is called with the .call function, so this gets reset to the component.
    graphMediator.updateComponent("currentFrame", callback);
    graphMediator.frameDependents("stockGraph");
    graphMediator.setRange(); //the current frame must be updated before set range should be used.

    //change the on-hover states based on what has been clicked.
    $(".timeframe-item-selected").switchClass("timeframe-item-selected", "timeframe-item");
    $(this).switchClass("timeframe-item", "timeframe-item-selected");
  }
}




function BuildPredictionGraph(defaults, graphName) {
  this.launch = function() {
    graphMediator.addComponents('defaults', defaults);
    graphMediator.defaultProcessor(); //creates the daily and intradayLines components. adds the price and date lines to both of those components.

    graphMediator.createPredictionLine("daily", "prediction"); //create this predictions graph line for the stock graph only.
    graphMediator.createPredictionLine("intraday", "prediction"); //create this predictions graph line for the stock graph only.

    graphMediator.createPredictionLine("daily", "predictionend"); //create this predictions graph line for the stock graph only.
    graphMediator.createPredictionLine("intraday", "predictionend"); //create this predictions graph line for the stock graph only.

    var currentFrame = {
      framesHash: graphMediator.framesHash("predictionGraph")
    };

    graphMediator.addComponents('currentFrame', currentFrame); //currentframe must be used before setRange is used.

    var bestRange = graphMediator.bestRange("prediction");
    graphMediator.updateComponent("currentFrame", function(component) {
      this.timeFrame = bestRange;
    });

    // sets the daily or intraday lines, depending on the timeFrame in the currentFrame. Also sets the hover state.
    graphMediator.frameDependents("stockGraph");

    // the timeFrame in the currentFrame component must be set before using this. 
    graphMediator.setRange();
  }

/*
  this.endPrediction = function(endTime, endPrice) { //endtime and price are passed by the ajax function.
    //need to set the endprediction line.
    //need to change the formatting on the first prediction line.
    //probably need to handle situation of overlapaping lines.
    //need to reset the endprediction line 

    graph["predictionend"] = [[graph["prediction"][0][0], graph["prediction"][0][1]],[endTime, endPrice]];
    graph["intraday_predictionend"] = IntradayPredictions(graph["predictionend"], undefined)[0];
    graph["daily_predictionend"] = DailyPredictions(graph["predictionend"], undefined)[0];

    if (currentRange["buttonType"] === "1D" || currentRange["buttonType"] === "5D") {
      chart.series[3].setData(graph["intraday_predictionend"]); //instead of resetting all series', just reset this one.
    }
    else {
      chart.series[3].setData(graph["daily_predictionend"]); //instead of resetting all series', just reset this one.
    }
  }

  function setSeries(button) {
    if ((button !== "1D" && button !== "5D") && (currentRange["buttonType"] === "1D" || currentRange["buttonType"] === "5D")) { //set daily graph
      chart.series[0].setData(graph["daily_prices"]); //all of these need to be set based on the button of best fit.
      chart.series[1].setData(graph["daily_forward_prices"]);
      chart.series[2].setData(graph["daily_prediction"]); //need the daily prediction and intraday predictions
      chart.series[3].setData(graph["daily_predictionend"]); //same with this. maybe null.
    }
    if ((button === "1D" || button === "5D") && (currentRange["buttonType"] !== "1D" && currentRange["buttonType"] !== "5D")) { //set intraday graph arrays
      chart.series[0].setData(graph["intraday_prices"]); //all of these need to be set based on the button of best fit.
      chart.series[1].setData(graph["intraday_forward_prices"]);
      chart.series[2].setData(graph["intraday_prediction"]); //need the daily prediction and intraday predictions
      chart.series[3].setData(graph["intraday_predictionend"]); //same with this. maybe null.
    }
    //reset these arrays after using the setdata. not sure why this is necessary.
    graph["intraday_prediction"] = IntradayPredictions(graph["prediction"], undefined)[0]; //the 0 says to return only the first element of the returned value, which is 
    graph["daily_prediction"] = DailyPredictions(graph["prediction"], undefined)[0]; //the extra array of 0s is there for the prediction ids processor, which i
    graph["intraday_predictionend"] = IntradayPredictions(graph["predictionend"], undefined)[0];
    graph["daily_predictionend"] = DailyPredictions(graph["predictionend"], undefined)[0];
  }
  */
}