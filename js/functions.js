  function return_folder(){

    var dir = document.getElementById("pname").value;
    const path = require('path');
    var folder = path.join(process.cwd(),'results',dir);

    return folder;
  }

  function upload(name) {

    var files = $(name)[0].files;
    var pfolder = return_folder();
    var fs = require('fs');
    var exec = require('child_process').exec; 

    if (fs.existsSync(pfolder)) {
      alert('Folder name already exists');
    } else{
      
      exec('mkdir ' + pfolder, function(error,stdout,stderr){ if(error!=null){ console.log('error :', error); }});
      for (var i = 0; i < files.length; ++i){
        exec("copy " + files[i].path + " "+ pfolder, function(error,stdout,stderr){
          document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
          if(error!=null){
            console.log('error :', error);
          }
        }); 
        document.getElementById("subject").innerHTML += files[i].name +"\n";
      }
        document.getElementById("subject").style.display = "block";
        document.getElementById("file").style.display = "block";
        document.getElementById("file1").style.display = "block";
        document.getElementById("button").style.display = "block";
        document.getElementById("subject").disabled = true;
        document.getElementById("file").disabled = true;
        document.getElementById("file1").disabled = true;
        document.getElementById("pname").disabled = true;
        document.getElementById("upload").style.display = "none";
        document.getElementById("fileDialog").style.display = "none";
        document.getElementById("submit").style.display = "none";
    }
  }

  function upload_reference(name,dir) {

    const path = require('path');
    var folder = path.join(process.cwd(),'VD',dir);
    var files = $(name)[0].files;
    var fs = require('fs');
    var exec = require('child_process').exec; 

    if (!fs.existsSync(folder)) {
      alert('Folder ' +dir+ ' does not exists');
    } else{
        for (var i = 0; i < files.length; ++i){
        exec("copy " + files[i].path + " "+ folder, function(error,stdout,stderr){
          document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
          if(error!=null){
            console.log('error :', error);
          } 
        }); 
         document.getElementById("subject").innerHTML += files[i].name +"\n";
      }
    }
  }

  function upload_localdb(name,dir,dbtype) {

    const path = require('path');
    var folder = path.join(process.cwd(),'VD',dir);
    var files = $(name)[0].files;
    var fs = require('fs');
    var exec = require('child_process').exec; 

    if (!fs.existsSync(folder)) {
      alert('Folder ' +dir+ ' does not exists');
    } else{
        for (var i = 0; i < files.length; ++i){
        exec("copy " + files[i].path + " "+ folder, function(error,stdout,stderr){
          document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
          if(error!=null){
            console.log('error :', error);
          } 
        }); 
         if (dir == 'databases'){
              format_db(path.join(folder,files[i].name),dbtype);
            }
         document.getElementById("subject").innerHTML += files[i].name +"\n";
      }
    }
  }

  function format_db(file,dbtype){
    const path = require('path');
    var formatdb = path.join(process.cwd(),'VD','bin','makeblastdb');
    var exec = require('child_process').exec; 
    var cmd = formatdb + " -in " + file + " -dbtype " + dbtype; console.log(cmd);

    exec(cmd, function(error,stdout,stderr){
      document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
      if(error!=null){
        console.log('error :', error);
        document.getElementById("subject").innerHTML += error +"\n";
      } 
    }); 
  }

  function run_fastqc() {

    const path = require('path');
    var dir = return_folder();
    var fs = require('fs');
	var fqcdir = path.join(process.cwd(),'VD', 'bin','fastQC');
     
    fs.readdir(dir, function(err, files) {
      var cfiles ="";
      
      for (var i = 0; i < files.length; ++i){
        cfiles = cfiles + path.join(dir , files[i]) + " "; 
      }

      var exec = require('child_process').exec; 
	  var commrun = "java -Xmx250m -classpath " + fqcdir + ";" + path.join(fqcdir,"sam-1.103.jar") + ";" + path.join(fqcdir,"jbzip2-0.9.jar") + " uk.ac.babraham.FastQC.FastQCApplication ";
	  
      exec(commrun + cfiles, function(error,stdout,stderr){
        document.getElementById("subject2").innerHTML += stdout +"\n" + stderr +"\n";

        if(error!=null){ console.log(commrun);
          document.getElementById("subject2").innerHTML += "ERRORR:" + error + "\n" ;
        }
      });

      var leftDiv = document.createElement("div"); 
      [].forEach.call(files, function (el) {
        var txt = "file://" + path.join(dir, path.parse(el).name) + "_fastqc.html";
        a = document.createElement('a');
        a.innerHTML = '<a target="_blank" href="' + txt + '" >' + el + '</a><br>';
        leftDiv.appendChild(a);
        document.getElementById("container").appendChild(leftDiv);
        document.getElementById("subject2").style.display = "block";
        document.getElementById("subject2").disabled = true;
        document.getElementById("button").style.display = "none";
        document.getElementById("trimming").style.display = "block";
        document.getElementById("analysis").style.display = "block";
      });

    })
  }

  function run_analysis(name){
    const path = require('path');
    var dir = document.getElementById(name).value;
    var fs = require('fs');
    var exec = require('child_process').exec; 
    var cfiles = "";
    var commrun = "perl " + path.join(process.cwd(),'VD','virus_detect.pl ');

    fs.readdir(dir, function(err, files) {

      //files.filter(extension).forEach(function(value) {
      files.forEach(function(value) {
          cfiles = cfiles + path.join(dir , value) + " "; 
         // document.getElementById("inputtext").innerHTML += value +"\n"; 
      }); 
console.log(cfiles);
        if(cfiles != ""){
          var db1 = document.getElementById("databases").value;
          var db = db1.replace(".nin", "");
		  var ref = document.getElementById("references").value;
		  var cores = document.getElementById("cores").value;
          commrun = (db != "") ?  commrun + " --reference " + db + " " : commrun;
          commrun = (ref != "") ? commrun + " --host_reference " + ref + " ": commrun;
          commrun = (cores != "") ? commrun + " --thread_num " + cores + " ": commrun;
          
          commrun += cfiles; console.log(commrun); console.log(ref);
          exec(commrun, function(error,stdout,stderr){
            console.log('stdout :', stdout); 
            console.log('stderr :', stderr); 
            document.getElementById("outputtext").innerHTML += stdout +"\n";
            if(error != null){
              console.log('error :', error); 
              document.getElementById("outputtext").innerHTML += error +"\n";
            }
          });
          document.getElementById("outputtext").innerHTML += commrun +"\n";
          document.getElementById("outputtext").style.display = "block";
        }

    });
  }

  function trimming(name){
        const path = require('path');
        var dir = document.getElementById(name).value;
        var fs = require('fs');
        var spawn = require('child_process').spawn;
		var cfiles = "";
		var cn = path.join(process.cwd(),'VD','tools','sRNA_clean','sRNA_clean.pl ');

        fs.readdir(dir, function(err, files) {
       
          files.filter(extension).forEach(function(value) {
              cfiles = cfiles + path.join(dir , value) + " "; 
          }); 

            if(cfiles != ""){

              var adapt = document.getElementById("adaptor").value;
              var len = document.getElementById("length").value;
			  var comando = spawn('perl',[cn,'-s',adapt,'-l',len,cfiles],{shell:true}); console.log(comando);
			  comando.stdout.on('data',(data) =>{ console.log('stdout: ${data}');});
			  comando.stderr.on('data',(data) =>{ console.log('stderr: ${data}');});
			  comando.on('close',function(code){
				  if(code === 0){
					dibujo(fs,dir);
				  }
			  })

              document.getElementById("outputtext").innerHTML += commrun +"\n";
              document.getElementById("alink").innerHTML = '<a target="_blank" href="file://' + dir + '" >Reports</a><br>';
              document.getElementById("adaptor").disabled = true;
              document.getElementById("length").disabled = true;
              document.getElementById("outputtext").disabled = true;
              document.getElementById("outputtext").style.display = "block";
              document.getElementById("resultLbl").style.display = "block";
              document.getElementById("analysis").style.display = "block";
              document.getElementById("save").style.display = "block";

            }

          });
		  
        function extension(element) {
          var extName = path.extname(element);
          return extName === '.fq'; 
        };
		function extension_sRNA(element) {
          var extName = new RegExp('sRNA_length.txt$');
          return extName.test(element); 
        };
		
		function dibujo(fs,dir){
			var sRNA='';  
			fs.readdir(dir, function(err, files1) {
			  files1.filter(extension_sRNA).forEach(function(value1) {
				  sRNA = path.join(dir , value1); 
			  }); 
			  if(sRNA != ''){
				  var element=[]; 
				  var str = fs.readFileSync(sRNA, "utf8");
				  var x = str.split('\n');

				  for (var i=0; i<x.length; i++) {
					if(!x[i].startsWith('#') && x[i] != ''){
					  y = x[i].split('\t');
					  x[i] = y;
					  element.push({"x": Number(x[i][0]),"y": Number(x[i][1]) });
					}
				  }

				  var margin = {top: 50, right: 50, bottom: 50, left: 50}
					, width = window.innerWidth - margin.left - margin.right 
					, height = window.innerHeight - margin.top - margin.bottom; 

				  var xScale = d3.scaleLinear()
					  .domain([d3.min(element, function(d) { return d.x; }), d3.max(element, function(d) { return d.x; })]) // input
					  .range([0, width-60]); // output

				  var yScale = d3.scaleLinear()
					  .domain([0, d3.max(element, function(d) { return d.y; })]) // input 
					  .range([height, 0]); // output 

				  var line = d3.line()
					  .x(function(d) { return xScale(d.x); }) // set the x values for the line generator
					  .y(function(d) { return yScale(d.y); }) // set the y values for the line generator 
					  .curve(d3.curveMonotoneX) // apply smoothing to the line

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

				  svg.append("g")
					  .attr("class", "y axis")
					  .call(d3.axisLeft(yScale)); // Create an axis component with d3.axisLeft

				  svg.append("path")
					  .datum(element)
					  .attr("class", "line")
					  .attr("d", line);  
			  }
			});
		}
  }



function save(){
  // saveSvgAsPng(document.getElementById("svg"), "diagram.png");

}


  function read_db(){

    const path = require('path');
    var dir = path.join(process.cwd(),'VD','databases');
    var fs = require('fs');

    fs.readdir(dir, function(err, files) {
      var select = document.getElementById("databases");
      files.filter(extension).forEach(function(value) {
        select.options[select.options.length] = new Option(value, value);
      });
    });

    function extension(element) {
	  var rege = new RegExp('vrl.+in$');
      return rege.test(element); 
    };
  }

  function read_reference(){

    const path = require('path');
    var dir = path.join(process.cwd(),'VD','databases');
    var fs = require('fs');

    fs.readdir(dir, function(err, files) {
      var select = document.getElementById("references");
      files.filter(extension).forEach(function(value) {
        select.options[select.options.length] = new Option(value, value);
      });
    });

    function extension(element) {
      var extName = path.extname(element);
	  var rege = new RegExp('^host_');
      return rege.test(element); 

    };
  }

  function link_trimming(){
    location.href = './clean.html';
  }

  function link_analysis(){
    location.href = './analysis.html';
  }
