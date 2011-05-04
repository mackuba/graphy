var Graphy = {

  DYGRAPH_OPTIONS: {
    legend: 'always',
    labelsDivWidth: 200,
    labelsSeparateLines: true,
    labelsDivStyles: {
      'margin-left': '225px',
      'line-height': '150%'
    },
    showRoller: true,
    xAxisLabelFormatter: Dygraph.dateAxisFormatter,
    xTicker: Dygraph.dateTicker,
    xValueFormatter: Dygraph.dateString_,
    xValueParser: function(x) { return parseInt(x, 10) * 1000 },
    yAxisLabelWidth: 70
  },

  initialize: function(sets, count) {
    for (var s = 0; s < sets.length; s++) {
      for (var i = 0; i < count; i++) {
        Graphy.drawGraph(i, sets[s]);
      }
    }

    if (sets.length > 1) {
      var setBar = $('#sets');
      setBar.append(this.createSetButton('', 'all'));
      for (var s = 0; s < sets.length; s++) {
        setBar.append(this.createSetButton(sets[s].name));
      }
      setBar.show();
      this.setupRouting();
    }
  },

  createSetButton: function(name, label) {
    label = label || name;
    return $('<li id="button_' + label + '"><a href="#/' + name + '">' + label + '</a></li>')
  },

  drawGraph: function(index, set) {
    var div = $('<div class="graph"></div>');
    div.appendTo('body');
    var divWidth = div.width();
    div.addClass(set.name);
    div.addClass('loading');

    var file = set.name + ".csv";
    if (index > 0) {
      file = file + "." + index;
    }

    $.ajax({
      url: file,
      success: function(data) {
        data = data.replace(/^.*/, "time," + set.labels.join(','));
        new Dygraph(div.get(0), data, $.extend(Graphy.DYGRAPH_OPTIONS, {
          yValueFormatter: function(x) { return ' ' + x + set.unit },
          width: divWidth
        }));
        div.removeClass('loading');
        div.addClass('loaded');
        div.append('<label>' + set.name + ' #' + (index + 1) + '</label>');
      },
      error: function() {
        div.remove();
      }
    });
  },

  showSet: function(name) {
    $('#sets li').removeClass('selected');
    if (name) {
      $('.graph.' + name).show();
      $('.graph:not(.' + name + ')').hide();
      $('#button_' + name).addClass('selected');
    } else {
      $('.graph').show();
      $('#button_all').addClass('selected');
    }
  },

  setupRouting: function() {
    var router = $.sammy(function() {
      this.get('#/', function() {
        Graphy.showSet(null);
      });
      this.get('#/:name', function() {
        Graphy.showSet(this.params['name']);
      });
    });
    router.run('#/');
  }
};
