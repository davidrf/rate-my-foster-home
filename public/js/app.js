$(document).ready(function(){
  if ($("#datepicker").length) {
    $("#datepicker").datepicker({
      dateFormat: "yy-mm-dd"
    });
  }

  if ($("#curve_chart").length) {
    $.get(window.location.pathname + "/data.json", function(response) {
      var data = response["data"][1][0];
      if (data) {
        google.setOnLoadCallback(drawChart(response["data"]));
      } else {
        $("#review_box").remove();
        $("#graph_container").remove();
        $("h4").text("No Reviews, Please Review");
      }
    });
  }

  if ($("#users_dropdown").length) {
    value = $("#users_dropdown").val();
    $.get(window.location.pathname + "/data.json", { user_id: value }, function(response) {
      for (var i = 0;i < response["data"].length;i++) {
        var home = response["data"][i];
        var html = "<option value=" + home["id"] + ">" + home["name"] + "</option>";
        $("#homes_dropdown").append(html);
      }
    }, "json" );
  }

  $("#users_dropdown").change(function() {
    $("#homes_dropdown").empty();
    value = $(this).val();
    $.get(window.location.pathname + "/data.json", { user_id: value }, function(response) {
      for (var i = 0;i < response["data"].length;i++) {
        var home = response["data"][i];
        var html = "<option value=" + home["id"] + ">" + home["name"] + "</option>";
        $("#homes_dropdown").append(html);
      }
    }, "json" );
  });

  if ($("#user_homes_dropdown").length) {
    value = $("#user_homes_dropdown").val();
    $.get(window.location.pathname + "/data.json", { user_id: value }, function(response) {
      for (var i = 0;i < response["data"].length;i++) {
        var home = response["data"][i];
        var html = htmlrow(home);
        $("#home_rows").append(html);
      }
    }, "json" );
  }

  $("#user_homes_dropdown").change(function() {
    value = $(this).val();
    $.get(window.location.pathname + "/data.json", { user_id: value }, function(response) {
      var html = "";
      for (var i = 0;i < response["data"].length;i++) {
        var home = response["data"][i];
        html += htmlrow(home);
      }
      $("#home_rows").empty();
      $("#home_rows").append(html);

    }, "json" );
  });
});

function drawChart(data) {
  data = google.visualization.arrayToDataTable(data);
  var options = {
    chartArea: { left: "80", top: "30", bottom: "0" },
    curveType: 'function',
    legend: { position: 'right' },
    interpolateNulls: true,
    hAxis: { title: "Review Date", slantedText: true},
    vAxis: { title: "Rating", viewWindow: { min: 0, max: 10}, ticks: [0, 1, 2, 3, 4, 5, 6, 7, 8 ,9, 10] },
  };

  var chart = new google.visualization.LineChart(document.getElementById('curve_chart'));
  chart.draw(data, options);
};

function htmlrow(home) {
  var html =  "<div class='row'>";
  html += "<div class='small-4 columns visible-for-small-only'>";
  html += "<span>" + home["name"] + "</span>";
  html += "</div>";
  html += "<div class='small-4 columns hidden-for-small-only'>";
  html += "<h3>" + home["name"] + "</h3>";
  html += "</div>";
  html += "<div class='small-8 columns'>";
  html += "<div class='row'>";
  html += "<div class='column'>";
  html += "<a href='/foster_home/" + home["id"] + "' class='button radius small expand'>Reviews</a>";
  html += "</div>";
  html += "</div>";
  html += "</div>";
  html += "</div>";
  return html;
};
