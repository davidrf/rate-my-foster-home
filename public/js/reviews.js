$(document).ready(function(){
  path = window.location.pathname + "/data.json";
  $.get(window.location.pathname + "/data.json", function(response) {
    google.setOnLoadCallback(drawChart(response["data"]));
  });
});

function drawChart(data) {
  data = google.visualization.arrayToDataTable(data);
  var options = {
    title: 'House Review',
    curveType: 'function',
    legend: { position: 'right' },
    interpolateNulls: true,
    hAxis: { slantedText: true},
    vAxis: { viewWindow: { min: 0, max: 10}, ticks: [0, 1, 2, 3, 4, 5, 6, 7, 8 ,9, 10] }
  };

  var chart = new google.visualization.LineChart(document.getElementById('curve_chart'));
  chart.draw(data, options);
};
