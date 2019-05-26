function save_html(folder){
    const path = require('path');
    var fs = require('fs');
    var x = $('#graph').html();
    var y = $('#graph1').html();
    var bb = $("head").html();
    fs.writeFileSync(path.join(folder,'results.html'), bb+x+y , 'utf-8');

}

function draw_sRNA_summary(sRNA_length,name){ console.log(sRNA_length);
	  if (sRNA_length != ""){
		d3.tsv(sRNA_length).then(function(data) { 
		if(data.length>1){
		  var margin = {top: 50, right: 50, bottom: 50, left: 50}
		  , width = window.innerWidth - margin.left - margin.right 
		  , height = window.innerHeight - margin.top - margin.bottom; 

		  var xScale = d3.scaleLinear()
			.domain([d3.min(data, function(d) { return Number(d.Size); }), d3.max(data, function(d) { return Number(d.Size); })]) // input
			.range([0, width-60]); // output

		  var yScale = d3.scaleLinear()
			.domain([0, d3.max(data, function(d) { return Number(d.file); })]) // input 
			.range([height, 0]); // output 

		  var line = d3.line()
			.x(function(d) { return xScale(Number(d.Size)); }) // set the x values for the line generator
			.y(function(d) { return yScale(Number(d.file)); }) // set the y values for the line generator 
			.curve(d3.curveMonotoneX); // apply smoothing to the line

		  var svg = d3.select("#graph").append("svg")
			.attr("id","svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom)
		  .append("g")
			.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

		  svg.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0," + height + ")")
			.call(d3.axisBottom(xScale)); // Create an axis component with d3.axisBottom

		  svg.append("text")
			.attr("transform",
				  "translate(" + (width/2) + " ," + 
								 (height*0.89 + margin.top + 20) + ")")
			.style("text-anchor", "middle")
			.text("Sequence lenght (bp)");

		  svg.append("g")
			.attr("class", "y axis")
			.call(d3.axisLeft(yScale)); // Create an axis component with d3.axisLeft

		  svg.append("text")
			.attr("transform", "rotate(-90)")
			.attr("y", 0 - margin.left)
			.attr("x",0 - (height / 2))
			.attr("dy", "1em")
			.style("text-anchor", "middle")
			.text("#Reads");  

		  svg.append("path")
			.datum(data)
			.attr("class", "line")
			.attr("d", line); 

		  svg.append("text")
			.attr("x",  (width/2))
			.attr("y", -margin.top/2  )
			.attr("dy", "1em")
			.style("text-anchor", "middle")
			.attr("font-weight",700)
			.text("Sample: " + name);  
		}
	  });
	}
}

	function draw_spike_summary(spike_file,name){
		if(spike_file!= ""){
		  d3.tsv(spike_file).then(function(data_sum) {
console.log(data_sum);
		if(data_sum.length>0){
		  var data = d3.nest()
			.key(function(d) { return d.pattern; })
			  .rollup(function(v) { return v.length; })
			.entries(data_sum);

		  var margin = {top: 50, right: 50, bottom: 50, left: 50}
		  , width = window.innerWidth - margin.left - margin.right 
		  , height = window.innerHeight - margin.top - margin.bottom; 

		  var g = d3.select("#graph1").append("svg")
			.attr("id","svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom)
		  .append("g")
			.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

		  var x = d3.scaleBand().rangeRound([0, width]).padding(0.1),
			y = d3.scaleLinear().rangeRound([height, 0]);

		  x.domain(data.map(function(d) { return d.key; }));
		  y.domain([0, d3.max(data, function(d) { return d.value; })]);

		  g.append("g")
			  .attr("class", "axis axis--x")
			  .attr("transform", "translate(0," + height + ")")
			  .call(d3.axisBottom(x));

		  g.append("g")
			  .attr("class", "axis axis--y")
			  .call(d3.axisLeft(y).ticks(10))
			.append("text")
			  .attr("transform", "rotate(-90)")
			  .attr("y", 6)
			  .attr("dy", "0.71em")
			  .attr("text-anchor", "end")
			  .text("Frequency");

		  g.selectAll(".bar")
			.data(data)
			.enter().append("rect")
			  .attr("class", "bar")
			  .attr("x", function(d) { return x(d.key); })
			  .attr("y", function(d) { return y(d.value); })
			  .attr("width", x.bandwidth())
			  .attr("height", function(d) { return height - y(d.value); });

		  g.append("text")
			.attr("transform", "rotate(-90)")
			.attr("y", 0 - margin.left)
			.attr("x",0 - (height / 2))
			.attr("dy", "1em")
			.style("text-anchor", "middle")
			.text("#Reads");

		  g.append("text")
			.attr("x",  (width/2))
			.attr("y", -margin.top/2  )
			.attr("dy", "1em")
			.style("text-anchor", "middle")
			.attr("font-weight",700)
			.text("Sample: " + name);   
		}
	  });
	}
}