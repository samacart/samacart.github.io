
# ---
# These global variables will be available 
# to all the transition functions 
# ---
paddingBottom = 30
paddingRight = 20
paddingTop = 20
paddingLeft = 50

width = 880 - paddingRight - paddingLeft
height = 600 - paddingBottom - paddingTop
duration = 750
curr = 'Countries'

# the domain of our scales will be set
# once we have loaded the data
x = d3.time.scale()
  .range([0, width])

y = d3.scale.linear()
  .range([height, 0])

color = d3.scale.category20()

# area generator to create the
# polygons that make up the
# charts
area = d3.svg.area()
    .interpolate("basis")
    .x((d) -> x(d.date))

# line generator to be used
# for the Area Chart edges
line = d3.svg.line()
    .interpolate("basis")
    .x((d) -> x(d.date))

# stack layout for streamgraph
# and stacked area chart
stack = d3.layout.stack()
  .values((d) -> d.values)
  .x((d) -> d.date)
  .y((d) -> d.count)
  .out((d,y0,y) -> d.count0 = y0)
  .order("reverse")

# axis to simplify the construction of
# the day lines
xAxis = d3.svg.axis()
  .scale(x)
  .tickSize(-height)
  .tickFormat(d3.time.format('%Y'))
  #.tickFormat(d3.time.format('%a %d'))

yAxis = d3.svg.axis()
  .scale(y)
  .orient("left")

# we will populate this variable with our
# data array, once its been loaded
data = null

# Create the blank SVG the visualization will live in.
svg = d3.select("#vis_area").append("svg")
  .attr("width", width + paddingRight + paddingLeft)
  .attr("height", height + paddingBottom + paddingTop)
  .append("g")
  .attr("transform", "translate(" + paddingLeft + "," + paddingTop + ")")

# ---
# Called when the chart buttons are clicked.
# Hands off the transitioning to a new chart
# to separate functions, based on which button
# was clicked. 
# ---
transitionTo = (name) ->
  if name == "stream"
    streamgraph()
  if name == "stack"
    stackedAreas()
  if name == "area"
    #groupedBar()
    areas()
  if name == "dataChange"
    dataChange()

# ---
# Swaps the data from regions to countries
# and rebuilds the svg and legedn
# --

dataChange = () ->
  if curr == 'Countries'
    curr = 'Regions'
    d3.json("data/countries.json", updateData)
  else
    curr = 'Countries'
    d3.json("data/regions.json", updateData)

updateData = (error, rawData) ->
  data = rawData
  parseTime = d3.time.format("%Y").parse

  data.forEach (s) ->
    s.values.forEach (d) ->
      d.date = parseTime(d.date)
      d.count = parseFloat(d.count)

    s.maxCount = d3.max(s.values, (d) -> d.count)

  data.sort((a,b) -> b.maxCount - a.maxCount) 

  svg.selectAll("*").remove()
  d3.select("#legend").selectAll("*").remove()

  d3.select("#stack").attr("class","btn btn-default active switch")
  d3.select("#dataChange").attr("class","btn btn-default switch").text("Switch To " + curr)

  start()  

# ---
# This is our initial setup function.
# Here we setup our scales and create the
# elements that will hold our chart elements.
# ---
start = () ->
  # first, lets setup our x scale domain
  # this assumes that the dates in our data are in order
  minDate = d3.min(data, (d) -> d.values[0].date)
  maxDate = d3.max(data, (d) -> d.values[d.values.length - 1].date)
  x.domain([minDate, maxDate])

  # In this instance, I know the max value of the y
  minCount = 0
  maxCount = 8919
  y.domain([minCount, maxCount])

  # D3's axis functionality usually works great
  # however, I was having some aesthetic issues
  # with the tick placement
  # here I extract out every other day - and 
  # manually specify these values as the tick 
  # values
  # Doesn't really apply since most of these are in years
  dates = data[0].values.map((v) -> v.date)
  index = 0
  dates = dates.filter (d) ->
    index += 1
    (index % 2) == 0

  xAxis.tickValues(dates)

  # the axis lines will go behind
  # the rest of the display, so create
  # it first
  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0,"+ height + ")")
    .call(xAxis)

  svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)

  # I want the streamgraph to emanate from the
  # middle of the chart. 
  # we can set the area's y0 and y1 values to 
  # constants to achieve this effect.
  area.y0(height / 2)
    .y1(height / 2)

  # now we bind our data to create
  # a new group for each region type
  g = svg.selectAll(".region")
    .data(data)
    .enter()

  regions = g.append("g")
    .attr("class", "region")

  # add some paths that will
  # be used to display the lines and
  # areas that make up the charts
  regions.append("path")
    .attr("class", "area")
    .style("fill", (d) -> color(d.key))
    .attr("d", (d) -> area(d.values))

  regions.append("path")
    .attr("class", "line")
    .style("stroke-opacity", 1e-6)

  # create the legend on the side of the page
  createLegend()

  # default to streamgraph display
  stackedAreas()
  #streamgraph()

# ---
# Code to transition to streamgraph.
#
# For each of these chart transition functions, 
# we first reset any shared scales and layouts,
# then recompute any variables that might get
# modified in other charts. Finally, we create
# the transition that switches the visualization
# to the new display.
# ---
streamgraph = () ->
  # 'wiggle' is the offset to use 
  # for streamgraphs.
  stack.offset("wiggle")

  # the stack layout will set the count0 attribute
  # of our data
  stack(data)

  # reset our y domain and range so that it 
  # accommodates the highest value + offset
  y.domain([0, d3.max(data[0].values.map((d) -> d.count0 + d.count))])
    .range([height, 0])

  svg.select(".y.axis")
      .transition()
      .duration(1000)
      .call(yAxis);
  # the line will be placed along the 
  # baseline of the streams, but will
  # be faded away by the transition below.
  # this positioning is just for smooth transitioning
  # from the area chart
  line.y((d) -> y(d.count0))

  # setup the area generator to utilize
  # the count0 values created from the stack
  # layout
  area.y0((d) -> y(d.count0))
    .y1((d) -> y(d.count0 + d.count))

  # clear any bars from the grouped bar chart
  svg.selectAll("rect") .remove()

  # here we create the transition
  # and modify the area and line for
  # each region group through postselection
  t = svg.selectAll(".region")
    .transition()
    .duration(duration)
 
  # D3 will take care of the details of transitioning
  # between the current state of the elements and
  # this new line path and opacity.
  t.select("path.area")
    .style("fill-opacity", 1.0)
    .attr("d", (d) -> area(d.values))

  # 1e-6 is the smallest number in JS that
  # won't get converted to scientific notation. 
  # as scientific notation is not supported by CSS,
  # we need to use this as the low value so that the 
  # line doesn't reappear due to an invalid number.
  t.select("path.line")
    .style("stroke-opacity", 1e-6)
    .attr("d", (d) -> line(d.values))

  d3.select("#textArea")
    .html("");
    
  d3.select("#textArea")
    .append("p")
    .html("This is the streamgraph view. This view removes some of the shape bias in the stacked area charts while preserving the total contribution effect. The important part from our perspective is that the overall trend is getting thinner as the stream progresses. Ultimately, we want the stream to converge to a zero width at the end, which means infant mortality has been reduced to zero.")

# ---
# Code to transition to Stacked Area chart.
#
# Again, like in the streamgraph function,
# we use the stack layout to manage
# the layout details.
# ---
stackedAreas = () ->
  # the offset is the only thing we need to 
  # change on our stack layout to have a completely
  # different type of chart!
  stack.offset("zero")
  # re-run the layout on the data to modify the count0
  # values
  stack(data)

  # the rest of this is the same as the streamgraph - but
  # because the count0 values are now set for stacking, 
  # we will get a Stacked Area chart.
  y.domain([0, d3.max(data[0].values.map((d) -> d.count0 + d.count))])
    .range([height, 0])

  line.y((d) -> y(d.count0))

  area.y0((d) -> y(d.count0))
    .y1((d) -> y(d.count0 + d.count))

  # clear any bars from the grouped bar chart
  svg.selectAll("rect") .remove()

  t = svg.selectAll(".region")
    .transition()
    .duration(duration)

  t.select("path.area")
    .style("fill-opacity", 1.0)
    .attr("d", (d) -> area(d.values))

  t.select("path.line")
    .style("stroke-opacity", 1e-6)
    .attr("d", (d) -> line(d.values))

  svg.select(".y.axis")
      .transition()
      .duration(1000)
      .call(yAxis);

  d3.select("#textArea")
    .html("");
    
  d3.select("#textArea")
    .append("p")
    .html("Infant mortality is decreasing with the MDG program. You can see each region and trace the global trend in this view. Hover over the legend boxes on the right to reveal the countries or regions. A stacked area chart is used to show the absolute contribution to the global total as measured by the MDGs. Tracing the uppermost line gives the global total, and you can see each independent region or country.")
# ---
# Code to transition to Area chart.
# ---
areas = () ->
  g = svg.selectAll(".region")

  # set the starting position of the border
  # line to be on the top part of the areas.
  # then it is immediately hidden so that it
  # can fade in during the transition below
  line.y((d) -> y(d.count0 + d.count))
  g.select("path.line")
    .attr("d", (d) -> line(d.values))
    .style("stroke-opacity", 1e-6)

 
  # as there is no stacking in this chart, the maximum
  # value of the input domain is simply the maximum count value,
  # which we precomputed in the display function 
  y.domain([0, d3.max(data.map((d) -> d.maxCount))])
    .range([height, 0])

  svg.select(".y.axis")
      .transition()
      .duration(1000)
      .call(yAxis);

  # the baseline of this chart will always
  # be at the bottom of the display, so we
  # can set y0 to a constant.
  area.y0(height)
    .y1((d) -> y(d.count))

  line.y((d) -> y(d.count))

  t = g.transition()
    .duration(duration)

  # transition the areas to be 
  # partially transparent so that the
  # overlap is better understood.
  t.select("path.area")
    .style("fill-opacity", 0.5)
    .attr("d", (d) -> area(d.values))

  # here we finally show the line 
  # that serves as a nice border at the
  # top of our areas
  t.select("path.line")
    .style("stroke-opacity", 1)
    .attr("d", (d) -> line(d.values))

  d3.select("#textArea")
    .html("");
      
  d3.select("#textArea")
    .append("p")
    .html("While stacked views are useful, this visualization lets you look at each region independently. The area chart lets you compare countries or regions to each other. You'll notice that the y-axis has resized since we're looking at individual values, not the aggregate total.")

# ---
# Grouped Bars 
# ---

groupedBar = () ->
  #console.log data[0]

  x = d3.scale.ordinal().domain(data[0].values.map((d) ->
    d.date
  )).rangeBands([
    0
    width
  ], .1)

  x1 = d3.scale.ordinal().domain(data.map((d) ->
    d.key
  )).rangeBands([
    0
    x.rangeBand()
  ])

  y.domain([0, d3.max(data.map((d) -> d.maxCount))])
    .range([height, 0])

  svg.select(".y.axis")
      .transition()
      .duration(1000)
      .call(yAxis);

  g = svg.selectAll('.region')
  t = g.transition().duration(duration)

  #t.select('.line').style('stroke-opacity', 1e-6).remove()
  #t.select('.area').style('fill-opacity', 1e-6).remove()

  t.select('.line').style('stroke-opacity', 1e-6)
  t.select('.area').style('fill-opacity', 1e-6)

  g.each (p, j) ->
    d3.select(this).selectAll('rect').data((d) ->
      d.values
    ).enter().append('rect').attr('x', (d) ->
      x(d.date) + x1(p.key)
    ).attr('y', (d) ->
      y d.count
    ).attr('width', x1.rangeBand()).attr('height', (d) ->
      height - y(d.count)
    ).style('fill', color(p.key)).style('fill-opacity', 1e-6).transition().duration(duration).style 'fill-opacity', 1

# ---
# Called on legend mouse over. Shows the legend
# ---
showLegend = (d,i) ->
  d3.select("#legend svg g.panel")
    .transition()
    .duration(500)
    .attr("transform", "translate(0,0)")

# ---
# Called on legend mouse out. Hides the legend
# ---
hideLegend = (d,i) ->
  d3.select("#legend svg g.panel")
    .transition()
    .duration(500)
    .attr("transform", "translate(165,0)")

# ---
# Helper function that creates the 
# legend sidebar.
# ---
createLegend = () ->
  legendWidth = 200
  legendHeight = 245
  legend = d3.select("#legend").append("svg")
    .attr("width", legendWidth)
    .attr("height", legendHeight)

  legendG = legend.append("g")
    .attr("transform", "translate(165,0)")
    .attr("class", "panel")

  legendG.append("rect")
    .attr("width", legendWidth)
    .attr("height", legendHeight)
    .attr("rx", 4)
    .attr("ry", 4)
    .attr("fill-opacity", 0.5)
    .attr("fill", "white")

  legendG.on("mouseover", showLegend)
    .on("mouseout", hideLegend)

  keys = legendG.selectAll("g")
    .data(data)
    .enter().append("g")
    .attr("transform", (d,i) -> "translate(#{5},#{10 + 40 * (i + 0)})")

  keys.append("rect")
    .attr("width", 30)
    .attr("height", 30)
    .attr("rx", 4)
    .attr("ry", 4)
    .attr("fill", (d) -> color(d.key))

  keys.append("text")
    .text((d) -> d.key)
    .attr("text-anchor", "left")
    .attr("dx", "2.3em")
    .attr("dy", "1.3em")
  
# ---
# Function that is called when data is loaded
# Here we will clean up the raw data as necessary
# and then call start() to create the baseline 
# visualization framework.
# ---
display = (error, rawData) ->
  # a quick way to manually select which calls to display. 
  #filterer = {"Europe": 1, "Eastern Mediterranean": 1, "Africa": 1, "Americas": 1, "Western Pacific":1, "South-East Asia":1}
  #data = rawData.filter((d) -> filterer[d.key] == 1)
  data = rawData

  # a parser to convert our date string into a JS time object.
  #parseTime = d3.time.format.utc("%x").parse
  #parseTime = d3.time.format.utc("%Y").parse
  parseTime = d3.time.format("%Y").parse

  # go through each data entry and set its
  # date and count property
  data.forEach (s) ->
    s.values.forEach (d) ->
      d.date = parseTime(d.date)
      d.count = parseFloat(d.count)

    # precompute the largest count value for each region type
    s.maxCount = d3.max(s.values, (d) -> d.count)

  data.sort((a,b) -> b.maxCount - a.maxCount)

  start()

# Document is ready, lets go!
$ ->
  # code to trigger a transition when one of the chart
  # buttons is clicked
  d3.selectAll(".switch").on "click", (d) ->
    d3.event.preventDefault()
    id = d3.select(this).attr("id")
    transitionTo(id)

  # load the data and call 'display'
  d3.json("data/regions.json", display)
  #d3.json("data/countries.json", display)

