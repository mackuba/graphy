var Graphy = {

  GRAPH_WIDTH: 1000,

  drawGraph: function(file) {
    var div = document.createElement('div');
    div.style.width = Graphy.GRAPH_WIDTH + 'px';
    document.getElementsByTagName('body')[0].appendChild(div);

    new Dygraph(div, file, {
      labels: [
        "time", "websocket_server", "flash_policy", "resque", "bluepilld",
        "redis-server", "mongodb", "Rack", "Passenger", "nginx"
      ],
      labelsDivWidth: 150,
      labelsDivStyles: {
        'margin-left': '175px',
        'line-height': '150%'
      },
      showRoller: true,
      xAxisLabelFormatter: Dygraph.dateAxisFormatter,
      xTicker: Dygraph.dateTicker,
      xValueFormatter: Dygraph.dateString_,
      xValueParser: function(x) { return parseInt(x, 10) * 1000 },
      yValueFormatter: function(x) { return " " + Dygraph.intFormat(Math.floor(x / 100) / 10) + "M" }
    });
  }
};
