//global variables
var dataset;
var WIDTH = 1000 //width
var HEIGHT = 500 //height
var TOP = 20
var RIGHT = 20
var BOTTOM = 20
var LEFT = 50

d3.csv("../data/MDG_3_Tertiary_Long.csv", function(error, data){
  if(error) {
  //if error is not null log to the console
    console.log(error)
  }

  else {
  
  //convert string data to numeric
  data.forEach(function(d){
    d.n = +d.n
    d.h = +d.h
  });

  var labelVar = 'year';
  var varNames = d3.keys(data[0])
      .filter(function (key) { return key == labelVar;});

  var color = d3.scale.ordinal()
          .range(["#001c9c","#101b4d","#475003","#9c8305","#d3c47c"]);

  color.domain(varNames);

  var seriesData = varNames.map(function (name) {
      dataWithNaN = data.map(function (d) {
          return {Year: d['year'], Country: d['Country'], parity: +d['parity']};
      });

      var fltData = dataWithNaN.filter( function(d) { return !isNaN(d.parity)});

      return {
        values: fltData
        }
    });

  //set global variable and generate visualization
  dataset = seriesData
  generateViz();

  }

});

function generateViz() {

  console.log(dataset)
  var margin = {top: 30, right: 20, bottom: 30, left: 50},
    width = 600 - margin.left - margin.right,
    height = 270 - margin.top - margin.bottom;
  
  // Set the ranges
  var x = d3.time.scale().range([0, width]);
  var y = d3.scale.linear().range([height, 0]);

  // Define the axes
  var xAxis = d3.svg.axis().scale(x)
      .orient("bottom").ticks(5);

  var yAxis = d3.svg.axis().scale(y)
      .orient("left").ticks(5);

  var line = d3.svg.line()
    .x(function (d) { return x(d.Year); })
    .y(function (d) { return y(d.value); });

  // Scale the range of the data
  x.domain(d3.extent(dataset, function(d) { return d.Year; }));
  y.domain([0, d3.max(dataset, function(d) { return d.parity; })]); 

  //create the SVG element
  // Adds the svg canvas
  var svg = d3.select("body")
      .append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
      .append("g")
          .attr("transform", 
                "translate(" + margin.left + "," + margin.top + ")");

// Nest the entries by symbol
    var dataNest = d3.nest()
        .key(function(d) {return d.Country;})
        .entries(dataset);

    // Loop through each symbol / key
    dataNest.forEach(function(d) {
        svg.append("path")
            .attr("class", "line")
            .attr("d", line(d.values)); 

    });

  // var series = vis.selectAll(".series")
  //     .data(dataset)
  //   .enter().append("g")
  //     .attr("class", "series");

  // series.append("path")
  //   .attr("class", "line")
  //   .attr("d", function (d) { return line(d.values); })
  //   .style("stroke-width", "4px")
  //   .style("fill", "none");

}