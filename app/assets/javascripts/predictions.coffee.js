function IntradayForwardPrices (startTime) {
  forwardArray = [];
  var i=0;
  var iterations = 390; //5 6.5 hour days of 5 minute itarations. 5 days necessary for the prediction details graph.
  while (i<=iterations) {
    timeSpot = startTime + i*5*60*1000;
    if (timeSpot.utcTimeInt().utcTimeStr().validStockTime()) {
      forwardArray.push([timeSpot, null]);
    }
    else {
      iterations += 1;
    }
    i += 1;
  }
  return forwardArray;
}


//end time is assumed to be an est number.
//the graph start time int is the end of the actual data array.
//whether that be the daily array or the intraday array, it gets the last day of data..
function DailyForwardPrices (startTime) {
  var forwardArray = [];
  var i = 0;
  var iterations = 1202; //cut this in half for testing purpses..
  while (i<=iterations) {
    timeSpot = startTime + i*24*3600*1000;
    if (timeSpot.utcTimeInt().utcTimeStr().validStockTime()) {
      forwardArray.push([timeSpot, null]);
    }
    else {
      iterations += 1;
    }
    i += 1;
  }
  return forwardArray;
}
//this could be put in the graph.js and just called later. It definitely should be put over there. Get it working first?
//the stockgraph container is not longer corrrect I dont think.
function resizeChart() {
  var height = $("#prediction-div").width()/3+30;
  $("#prediction-div").css("height", height);
  $(".stockgraph-container1").css("height", height+10);
};

//Global variables 
var graph;
var chart1;
var currentRange;
var rangeHash = {};

$(document).ready(function () {
  resizeChart();
  $(window).bind("orientationchange resize", resizeChart);

  seriesVar = [
    {
      name : gon.ticker_symbol,
      dataGrouping: {
        enabled: false
      }
    },
    {
      name: "dateseries",
      lineWidth: 1,
      dataGrouping: {
        enabled: false
      }
    },
    {
      name:"myprediction",
      marker : {
        enabled : true,
        radius : 4,
        color: "#DC143C"
      },
      dataGrouping: {
        enabled: false
      }
    },
    {
      name:"endprediction",
      dataGrouping: {
        enabled: false
      },
      lineWidth: 2
    }
  ];

  chart = new Highcharts.StockChart({
    chart: {
      renderTo: 'prediction-div',
      panning: false,
      pinchType: false
    },
    rangeSelector : {
      enabled: false
    },
    scrollbar: {
      enabled: false
    },
    plotOptions: {
      series: {
          turboThreshold: 0
      }
    },
    navigator: {
      enabled: false
    },
    xAxis: {
      minRange: 3600 * 1000
    },
    series: seriesVar
  });


  var apiUrl = "/predictions/" + gon.prediction_id + ".json";
  chart.showLoading('Loading data from server');
  $.getJSON(apiUrl, function (data) {

    graph = data;

    chartFunctions = ChartFunctions(graph, chart);

    graph["daily_forward_prices"] = DailyForwardPrices(graph["daily_prices"].last()[0]);
    graph["intraday_forward_prices"] = IntradayForwardPrices(graph["intraday_prices"].last()[0]);

    chart.series[0].setData(graph["daily_prices"]);
    chart.series[1].setData(graph["daily_forward_prices"]);
    chart.series[2].setData(graph["prediction"]);
    if (graph["predictionend"].length >= 1) { //this will be empty if the prediction end is not present.
      chart.series[3].setData(graph["predictionend"]);
    }
    chart.hideLoading();

    //create prediction arrays where predictions ending that day are rounded to the end of the day to appear nicely on the 1m+ graphs.
    //graph["prediction"] = DailyPredictions(graph["my_prediction"], graph["daily_prices"].last()[0]);
    //this is not quite done yet. I need to make it work on prediction input as well.
    //that will be a bit more complex.

    //create the rangeHash to be used by the buttons.
    //note that by adding the my_prediction here, it will fall under the limited array filter.
    //the daily_predictions and daily_my_predictions are used here because the default setting is a monthly graph.
    graphSettings = {intradayPrices: graph["intraday_prices"], dailyPrices:graph["daily_prices"], predictions:graph["prediction"]};
    rangeHash = new PredictionGraphButtons(graphSettings);

    //chart.yAxis[0].setExtremes(rangeHash["1m"]["yMin"], rangeHash["1m"]["yMax"]);
    //chart.xAxis[0].setExtremes(rangeHash["1m"]["xMin"], rangeHash["1m"]["xMax"]);

    //currentRange = {rangeHash:rangeHash["1m"],buttonType:"1m"};
  });


  function getRanges1() {
    //the trick is that the graph ranges has to be defined... 
    //replace these with the graph["ranges"]["3m"] variable, ect.. maybe pass that variable in through the function.
    buttonType = $(this).data("button-type");
    ranges = rangeHash[buttonType];


    //originally i wanted to change the frequency with which the data arrays are reset, but it doesn't seem to matter.
    if (buttonType == "1d" || buttonType == "5d") {
      chart.series[0].setData(graph["intraday_prices"]);
      chart.series[1].setData(graph["intraday_forward_prices"]);

      //set the prediction arrays to the precise times if the graph is looking at 5d or 1d.
      chart.series[2].setData(graph["prediction"]);
    }
    else { //current range is not one of these, load the daily prices.
      chart.series[0].setData(graph["daily_prices"]);
      chart.series[1].setData(graph["daily_forward_prices"]);

      //set the prediction arrays so that today's predictions are rounded forward so that they don't appear to end before the graph does.
      chart.series[2].setData(graph["prediction"]);
    }

    chart.yAxis[0].setExtremes(ranges["yMin"], ranges["yMax"]);
    chart.xAxis[0].setExtremes(ranges["xMin"], ranges["xMax"]);

    currentRange = {rangeHash:rangeHash[buttonType], buttonType:buttonType};
    
    //window.alert(range_min + range_max)
  };

  function predictionXMax(endTime){
    return endTime+(endTime-currentRange["rangeHash"]["xMin"])*0.05;
  };
  function predictionYMax(endPrice){
    return endPrice+(endPrice-currentRange["rangeHash"]["yMin"])*0.1;
  };
  function predictionYMin(endPrice){
    return endPrice-(endPrice-currentRange["rangeHash"]["yMin"])*0.1;
  };

  //when a prediction is input, the graph ranges must be updated with new y max and mins so the button ranges include that
  //prediction.
  function updateRanges(endTime, endPrice){
    for (var value in rangeHash) {
      if (endPrice <= rangeHash[value]["yMin"] && endTime <= rangeHash[value]["xMax"]) {
        rangeHash[value]["yMin"] = predictionYMin(endPrice);
      }
      if (endPrice >= rangeHash[value]["yMax"] && endTime <= rangeHash[value]["xMax"]) {
        rangeHash[value]["yMax"] = predictionYMax(endPrice);
      }
    };
  };
  
  //window.function has the affect of setting the function as a global function, and its available in the ajax function.
  //updatePredictions adjsuts the graph ranges to show a prediction when it is put onto the graph.
  window.updatePredictions = function(endTime, endPrice) {
    
    /*if (currentRange["buttonType"] != "1d" && currentRange["buttonType"] != "5d") {
      if (endTime < graph["daily_prices"].last()[0]) {
        
      }
    }*/

    chart.series[3].setData([[endTime, endPrice]]);

    if (endTime > currentRange["rangeHash"]["xMax"]) { //if the endtime of the prediction is greater than the endtime in the current view, increase the end time.
      chart.series[0].setData(graph["daily_prices"]); //update to the daily price history array.
      chart.series[1].setData(graph["daily_forward_prices"]); //update to the daily forward price array.
      
      chart.xAxis[0].setExtremes(rangeHash["1m"]["xMin"], predictionXMax(endTime)); //set to the 1 month min range by default. This lookback window should be larger for large predictions so that the current stock data doesn't look disproportionately small after the prediction is made.
      chart.yAxis[0].setExtremes(rangeHash["1m"]["yMin"], rangeHash["1m"]["yMax"]);
      current_range = rangeHash["1m"]
    }
    if (endPrice >= currentRange["rangeHash"]["yMax"]) { //increase the y max if the end price is greater than the current max.
      chart.yAxis[0].setExtremes(currentRange["rangeHash"]["yMin"], predictionYMax(endPrice));
    }
    if (endPrice <= currentRange["rangeHash"]["yMin"]) { //increase the y min if the end price is lower than the current max.
      chart.yAxis[0].setExtremes(predictionYMin(endPrice), currentRange["rangeHash"]["yMax"]);
    }

    updateRanges(endTime, endPrice);
  };

  window.removePrediction = function() {
    chart.series[3].setData([null, null]);
    //reset the ranges on the buttons to be the original range amounts after the prediction is removed.
    var graphSettings = {intradayPrices: graph["intraday_prices"], dailyPrices:graph["daily_prices"], predictions:graph["predictions"]};
    rangeHash = new StockGraphButtons(graphSettings); //recreate the original ranges based on the data arrays.
    
    var buttonType = currentRange["buttonType"];
    chart.yAxis[0].setExtremes(rangeHash[buttonType]["yMin"], rangeHash[buttonType]["yMax"]); //reset the ranges to the new maxes without the prediction.
    chart.xAxis[0].setExtremes(rangeHash[buttonType]["xMin"], rangeHash[buttonType]["xMax"]);

    currentRange = {rangeHash:rangeHash[buttonType],buttonType:buttonType}; //reset the current range based on the new range hash.
  };

  //$("button[data-x-range-min]").click(get_ranges);
  $("button[data-button-type]").click(getRanges1);
  //remove branding logo that says 'highcarts'
  $("text").remove( ":contains('Highcharts.com')" );
});





