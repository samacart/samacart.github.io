//global variables
var dataset;
var w = 600 //width
var h = 200 //height

d3.csv("../data/collatz_output.csv", function(error, data){
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

  //set global variable and generate visualization
  dataset = data
  generateViz();
  }
});

function generateViz(){

  //set up scales
  var xScale = d3.scale.ordinal()
  .domain(d3.range(dataset.length))
  .rangeRoundBands([0,w],0.05);

  var yScale = d3.scale.linear()
  .domain([0, d3.max(dataset, function(d){return d.n;})])
  .range([0, h - 20]);

  //create the SVG element
  var svg = d3.select("#d3_test")
  .append("svg")
  .attr("width",w)
  .attr("height",h);

  //create the bars
  svg.selectAll("rect")
  .data(dataset)
  .enter()
  .append("rect")
  .attr("x", function(d,i){return xScale(i);})
  .attr("y", function(d){return h - yScale(d.n);})
  .attr("width", xScale.rangeBand())
  .attr("height", function(d){return yScale(d.n);})
  .attr("fill", function(d){
    if (d.h == 0){
    return "rgb(127,0,255)";
    } else if (d.h == 1){
    return "rgb(0,0,255)";
    } else {
    return "rgb(255,153,51)";
    }
  })

  //create labels
  svg.selectAll("text")
  .data(dataset)
  .enter()
  .append("text")
  .text(function(d){return(d.n);})
  .attr("text-anchor", "middle")
  .attr("x", function(d,i){return xScale(i) + xScale.rangeBand() / 2;})
  .attr("y", function(d){return h - yScale(d.n) - 2;})
  .attr("font-family", "sans-serif")
  .attr("font-size", "12px")
  .attr("fill", "black")

}
