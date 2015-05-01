function resizeChart() {
  var height = $("#stock-div").width()/3+30;
  $("#stock-div").css("height", height);
  $(".stockpage-graph").css("height", height+10);
};

//Global variables. Move these inside the doc ready after debugging is complete.
var stockGraph;

$(document).ready(function () {

  

  resizeChart();
  $(window).bind("orientationchange resize", resizeChart);

  Highcharts.setOptions({
    global: {
       timezoneOffset: 7 * 60,
       getTimezoneOffset: function (timestamp) {
         moment.tz.add('America/New_York|EST EDT|50 40|0101|1Lz50 1zb0 Op0');
         var zone = 'America/New_York';
         timezoneOffset = moment.tz.zone(zone).parse(timestamp);
         return timezoneOffset;
       }
    }
  });

  seriesVar = [
    {
      name : "prices",
      lineWidth: 2,
      dataGrouping: {
        enabled: false
      }
    },
    {
      name: "dateseries",
      lineWidth : 0,
      dataGrouping: {
        enabled: false
      }
    },
    {
      name : "predictions",
      lineWidth : 0,
      color: "#90ED7D",
      dataGrouping: {
        enabled: false
      },
      marker : {
        enabled : true,
        radius : 5,
        symbol: "triangle"
      }
    },
    {
      name:"my_prediction",
      color: "#f7a35c",      
      marker : {
        enabled : true,
        radius : 5,
        symbol: "triangle",
      },
      dataGrouping: {
        enabled: false
      }
    }
  ];

  stockChart = new Highcharts.StockChart({
    chart: {
      backgroundColor:'transparent',
      renderTo: 'stock-div',
      panning: false, //disables time frame dragging on desktop
      pinchType: false, //disable time frame dragging on mobile.
      spacingLeft: 0,
      spacingRight: 1
    },
    exporting: {
      enabled: false
    },
    plotOptions: {
      series: {
        turboThreshold: 0,
        cursor: 'pointer',
        marker: {
          states: {
            hover: { //select state doesnt work here.
              radius: 4, //radius of the on-hover ball
              lineWidth: 2, //width of the line around the ball
              lineColor: "#FFF"
            }
          }
        },
        states: { //no select state for the series.
          hover: {
            lineWidthPlus: 0,
            halo: {
              size: 0 //gets rid of the halo effect.
            }
          }
        },
        /*point: {
          events: {
            select: function() {
              //if (freezeHover == false) {
                this.series.update({
                  color: "#FFF"
                });
              //}
              //else {
              //  freezeHover = false;
              //}

              /*if(this.series.name == 'my_prediction') {
                var arrId = this.series.data[0].index;
                var predictionId = stockGraph["my_prediction_id"][arrId];
                location.href = '/predictions/'+predictionId;  
              }
              if(this.series.name == 'predictions') {
                var arrId = this.series.data[0].index;
                var predictionId = stockGraph["prediction_ids"][arrId];
                location.href = '/predictions/'+predictionId;  
              
            }
          }
        }*/
      }
    },
    tooltip: {
      crosshairs: null,
      shared: false
    },
    rangeSelector : {
      enabled: false
    },
    scrollbar: {
      enabled: false
    },
    navigator: {
      enabled: false
    },
    yAxis: {
      gridLineColor: 'rgba(255, 255, 255, 0.39)',
      gridLineWidth: 0,
      lineWidth: 1,
      lineColor: 'rgba(255, 255, 255, 0.39)',
      tickColor: 'rgba(255, 255, 255, 0.39)',
      tickLength: 5,
      tickWidth: 1,
      tickPosition: "inside",
      showFirstLabel: false,
      showLastLabel: false,
      startOnTick: true,
      endOnTick: true,
      labels: {
        style: {color:"rgba(255, 255, 255, 0.39)", "font-size": "11px", "font-family":"Lato", "font-weight": "300"},
        formatter: function() {
          return "$" + this.value;
        },
        x: -10,
        y: 5
      }
    },
    xAxis: {
      minRange: 3600 * 1000,
      //labels: {
      //  enabled: false
      //},
      //minorTickLength: 0,
      //tickLength: 0,
      lineColor: 'rgba(255, 255, 255, 0.39)',
      lineWidth: 1,
    },

    series: seriesVar
  });

  var apiUrl = "/stockprices/" + gon.ticker_symbol + ".json";
  var getRanges1;
  
  $.ajax({
    type: 'GET',
    url: apiUrl,
    async: true,
    cache: true,
    crossDomain: false,
    contentType: "application/json; charset=utf-8",
    dataType: 'json',
    success: function (data, status) {
      stockGraph = data; //assign the data to the graph var to be used globally. Delete this once debugging is done.


      var defaults = { //defaults contains the variables that are standard to each graph.
        "data": data,
        "chart": stockChart
      };

      graphMediator.addComponents('defaults', defaults);
      graphMediator.defaultProcessor(); //creates several default components automatically for every graph.

      graphMediator.createPredictionLine("daily", "predictions"); //create this predictions graph line for the stock graph only.
      graphMediator.createPredictionLine("intraday", "predictions"); //create this predictions graph line for the stock graph only.

      graphMediator.createPredictionLine("daily", "myPrediction"); //create this predictions graph line for the stock graph only.
      graphMediator.createPredictionLine("intraday", "myPrediction"); //create this predictions graph line for the stock graph only.

      var currentFrame = {
        timeFrame: "1Yr", 
        framesHash: graphMediator.framesHash("stockGraph")
      };
      graphMediator.addComponents('currentFrame', currentFrame); //currentframe must be used before setRange is used.

      // sets the daily or intraday lines, depending on the timeFrame in the currentFrame.
      graphMediator.frameDependents("stockGraph");

      // the timeFrame in the currentFrame component must be set before using this. 
      graphMediator.setRange();

      //stockChartFunctions = new StockGraph(data, stockChart); //data is passed into the stockgraph class so that it is accessible there.

      //stockChartFunctions.startChart();

      var buttonClick = function() {
        var buttonType = $(this).data("button-type");
        var callback = function(component) { this.timeFrame = buttonType }; //the cb is called with the .call function, so this gets reset to the component.
        graphMediator.updateComponent("currentFrame", callback);
        graphMediator.frameDependents("stockGraph");
        graphMediator.setRange(); //the current frame must be updated before set range should be used.

        //change the on-hover states based on what has been clicked.
        $(".timeframe-item-selected").switchClass("timeframe-item-selected", "timeframe-item");
        $(this).switchClass("timeframe-item", "timeframe-item-selected");
      }

      $("div[data-button-type]").click(buttonClick);

      // window.inputPrediction = function(endTime, endPrice, predictionId) {
      //   stockChartFunctions.inputPrediction(endTime, endPrice, predictionId); //when a prediction is input, this function fires from the predicitoninput ajax call.
      // }

      // window.removePrediction = function() {
      //   stockChartFunctions.removePrediction();
      // }
    }
  });

  $("text").remove( ":contains('Highcharts.com')" );


});