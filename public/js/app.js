$(document).ready(function(){
  if ($("#datepicker").length) {
    $("#datepicker").datepicker({
      dateFormat: "yy-mm-dd"
    });
  }

  if ($("#curve_chart").length) {
    $.get(window.location.pathname + "/data.json", function(response) {
      if (response["data"][0].length > 1) {
        google.setOnLoadCallback(drawChart(response["data"]));
      } else {
        $("#curve_chart").append("<h2>No Reviews, Please Review</h2>");
      }
    });
  }
});

function drawChart(data) {
  data = google.visualization.arrayToDataTable(data);
  var options = {
    title: 'House Review',
    curveType: 'function',
    legend: { position: 'right' },
    interpolateNulls: true,
    hAxis: { slantedText: true},
    vAxis: { viewWindow: { min: 0, max: 10}, ticks: [0, 1, 2, 3, 4, 5, 6, 7, 8 ,9, 10] },
    width: $("#curve_chart").width(),
    height: $("#curve_chart").height()
  };

  var chart = new google.visualization.LineChart(document.getElementById('curve_chart'));
  chart.draw(data, options);
};
