var Graphy = {

  GRAPH_WIDTH: 1000,

  DYGRAPH_OPTIONS: {
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
  },

  drawGraphs: function(sets, count) {
    for (var s = 0; s < sets.length; s++) {
      for (var i = 0; i < count; i++) {
        Graphy.drawGraph(sets[s].name + ".csv" + ((i > 0) ? ("." + i) : ''), sets[s]);
      }
    }
  },

  drawGraph: function(file, set) {
    var div = $('<div></div>');
    div.css('width', Graphy.GRAPH_WIDTH + 'px');
    div.appendTo('body');
    div.hide();

    $.get(file, function(data) {
      data = data.replace(/^.*/, "time," + set.labels.join(','));
      new Dygraph(div.get(0), data, $.extend(Graphy.DYGRAPH_OPTIONS, {
        yValueFormatter: function(x) { return " " + x + set.unit }
      }));
      div.show();
    });
  }
};
