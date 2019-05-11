  function return_folder(){

    var dir = document.getElementById("pname").value;
    const path = require('path');
    var folder = path.join(process.cwd(),'results',dir);

    return folder;
  }

  function upload(name) {

    var files = $(name)[0].files;
    const path = require('path');
    var fs = require('fs');
    var exec = require('child_process').exec; 

    var dir = document.getElementById("pname").value;
    var pfolder = path.join(process.cwd(),'results',dir); 

    if (fs.existsSync(pfolder)) {
      alert('Folder name already exists, choose another folder name');
    } else{
      
      exec('md ' + pfolder, function(error,stdout,stderr){ 
        if(error!=null){ alert('error :', error); }
        else {
          
          for (var i = 0; i < files.length; ++i){
              var tmp = files[i].name;
              // var newname1 = tmp.replace(".", "-");
              var newname = tmp.replace(" ", "-");

              exec("copy " + files[i].path + " "+  path.join(pfolder,newname) , function(error,stdout,stderr){
                // document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
                if(error!=null){
                  console.log('error :', error);
                  alert('Something went wrong while copying files.' + error);
                } else{
                  document.getElementById("ruta").value = pfolder;
                }
              }); 
          }
          //document.getElementById("container").removeChild(document.getElementById("remove"));
        }
      });
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
        exec("copy " + files[i].path + " "+ path.join(folder,"host_"+files[i].name), function(error,stdout,stderr){
          if(error!=null){
            alert(error);
            return;
          } 
          alert("Done!");
        }); 
      }
    }
  }

  function upload_localdb(name,prot_name,dir) {

   if (!($(prot_name)[0].value =="") && !($(name)[0].value =="" )){
      const path = require('path');
      var folder = path.join(process.cwd(),'VD',dir);
      var files = $(name)[0].files;
      var files_prot = $(prot_name)[0].files;
      var fs = require('fs');
      var exec = require('child_process').exec; 

      if (!fs.existsSync(folder)) {
        alert('Folder ' +dir+ ' does not exists');
      } else{
          for (var i = 0; i < files.length; ++i){ 
          var tmp = files[i].name;
          var tmp1 = tmp.replace(".fasta", "");
          var dbname  = "l_" +  tmp.replace(".fa", "");
          var commrun = "copy " + files[i].path + " "+ path.join(folder,dbname) + " & copy " + files_prot[i].path + " "+ path.join(folder,dbname + "_prot") ;
          
          exec(commrun, function(error,stdout,stderr){
            document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
            if(error!=null){
              console.log('error :', error);
            } 
          }); 
           if (dir == 'databases'){
                format_db(path.join(folder,dbname),"nucl");
                format_db(path.join(folder,dbname + "_prot"),"prot");
  			        format_faidx(path.join(folder,dbname));
              }
           document.getElementById("subject").innerHTML += files[i].name +"\n";
        }
      }
    }
    else alert("Select nucleotide and protein files");
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
  
  function format_faidx(file){
    const path = require('path');
    var formatdb = path.join(process.cwd(),'VD','bin','samtools');
    var exec = require('child_process').exec; 
    var cmd = formatdb + " faidx " + file; console.log(cmd);

    exec(cmd, function(error,stdout,stderr){
      document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
      if(error!=null){
        console.log('error :', error);
        document.getElementById("subject").innerHTML += error +"\n";
      } 
    }); 
  }

  function run_fastqc(dir) {

    const path = require('path');
    var fs = require('fs');
	  var fqcdir = path.join(process.cwd(),'VD', 'bin','fastQC');
     
    fs.readdir(dir, function(err, files) {
      var cfiles =""; 
      files.filter(extension_fastq).forEach(function(value) {
          cfiles = cfiles + path.join(dir , value) + " "; 
      });

      if (cfiles != ""){
        var exec = require('child_process').exec; 
  	    var commrun = "java -Xmx250m -classpath " + fqcdir + ";" + path.join(fqcdir,"sam-1.103.jar") + ";" + path.join(fqcdir,"jbzip2-0.9.jar") + " uk.ac.babraham.FastQC.FastQCApplication ";
  	   
        exec(commrun + cfiles, function(error,stdout,stderr){
          // document.getElementById("subject2").innerHTML += stdout +"\n" + stderr +"\n";

          if(error!=null){ console.log(commrun);
            console.log("fastqc error:",error);
           // document.getElementById("subject2").innerHTML += "ERRORR:" + error + "\n" ;
          }
        });

        var leftDiv = document.createElement("div"); 
        [].forEach.call(files, function (el) {
          var txt = "file://" + path.join(dir, path.parse(el).name) + "_fastqc.html";
          a = document.createElement('a');
          a.innerHTML = '<a target="_blank" href="' + txt + '" >' + el + '</a><br>';
          leftDiv.appendChild(a);
          // document.getElementById("container").appendChild(leftDiv); 
          // document.getElementById("subject2").style.display = "block";
          // document.getElementById("subject2").disabled = true;
          // document.getElementById("button").style.display = "none";
          // document.getElementById("div-fastqc").style.display = "block";
          // document.getElementById("trimming2").style.display = "block";
          // document.getElementById("analysis").style.display = "block";
        });
      }
    });
  }

  function analysis(){
      if(document.getElementById("fileDialog").style.display == "none"){
        run_analysis('ruta');
      } else{
        run_analysis('fileDialog');
      }
  }

  function run_analysis(dir,trim){
    const path = require('path');
    var fs = require('fs');
    var exec = require('child_process').exec; 
    var cfiles = "";
    var runperl = path.join("perlfiles","tmp.bat");
    var commrun = "perl " + path.join(process.cwd(),'VD','virus_detect.pl ');

    fs.readdir(dir, function(err, files) {
      if(trim){
        files.filter(extension_cleanfastq).forEach(function(value) {
        //files.forEach(function(value) {
            cfiles = cfiles + path.join(dir , value) + " "; 
           // document.getElementById("inputtext").innerHTML += value +"\n"; 
        }); 
      }

      if(cfiles == ""){
        files.filter(extension_fastq).forEach(function(value) {
            cfiles = cfiles + path.join(dir , value) + " "; 
        }); 
      }

      if(cfiles != ""){
        var db1 = document.getElementById("databases").value;
        var db = db1.replace(".nin", "");
  		  var ref = document.getElementById("references").value;
  		  var cores = document.getElementById("cores").value;
        commrun = (db != "") ?  commrun + " --reference " + db + " " : commrun;
        commrun = (ref != "") ? commrun + " --host_reference " + ref + " ": commrun;
        commrun = (cores != "") ? commrun + " --thread_num " + cores + " ": commrun;
        
        commrun += cfiles; console.log(commrun);
        
        create_analysisbat(runperl, commrun);

        if(fs.existsSync(runperl)){

            exec(runperl, function(error,stdout,stderr){
              console.log('stdout :', stdout); 
              console.log('stderr :', stderr); 
              // document.getElementById("outputtext").innerHTML += stdout +"\n";
              fs.writeFile(path.join(dir,"analysis.log"), commrun + "\n" + stdout, (err) => {   if (err) throw err; });

              if(error != null){
                console.log('analysis error :', error); 
                // document.getElementById("outputtext").innerHTML += error +"\n";
                fs.writeFile(path.join(dir,"analysis.log"), commrun + "\n" + error, (err) => {   if (err) throw err; });
                alert("There is an error. Please check analysis.log!");
                return;
              }
              alert("Done!");
            });
          }
        // document.getElementById("outputtext").innerHTML += commrun +"\n";
        // document.getElementById("outputtext").style.display = "block";
      }
    });
  }

  function trim(){
    if(document.getElementById("fileDialog").style.display == "none"){
      trimming('ruta');
    } else{
      trimming('fileDialog');
    }
  }

  function trimming(dir){
        const path = require('path');
        var fs = require('fs');
        var spawn = require('child_process').spawn;
		    var cfiles = "";
		    var cn = path.join(process.cwd(),'VD','tools','sRNA_clean','sRNA_clean.pl ');
        var runperl = path.join("perlfiles","tmp.bat");

        fs.readdir(dir, function(err, files) {
       
          files.filter(extension_fastq).forEach(function(value) {
              cfiles = cfiles + path.join(dir , value) + " "; 
          }); 

            if(cfiles != ""){

              var adapt = document.getElementById("adaptor").value;
              var len = document.getElementById("length").value;
              var commrun = 'perl ' + cn + ' -s '+ adapt + ' -l ' + len + ' ' + cfiles;

              create_analysisbat(runperl, commrun);

      			  // var comando = spawn('perl',[cn,'-s',adapt,'-l',len,cfiles],{shell:true});
              var comando = spawn(runperl,[],{shell:true});
              comando.stdout.on('data',(data) =>{ console.log('stdout: ${data}');});
      			  comando.stderr.on('data',(data) =>{ console.log('trimming stderr: ${data}');});
      			  comando.on('close',function(code){
      				  if(code === 0){
      					dibujo(fs,dir);
      				  }
      			  })

              // document.getElementById("outputtext").innerHTML += commrun +"\n";
              // document.getElementById("alink").innerHTML = '<a target="_blank" href="file://' + dir + '" >Reports</a><br>';
              // document.getElementById("adaptor").disabled = true;
              // document.getElementById("length").disabled = true;
              // document.getElementById("outputtext").disabled = true;
              // document.getElementById("outputtext").style.display = "block";
              // document.getElementById("resultLbl").style.display = "block";
              // document.getElementById("analysis").style.display = "block";
              // document.getElementById("save").style.display = "block";
              document.getElementById("ruta").value = dir;

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

    				 //  var svg = d3.select("#graph").append("svg")
    					//   .attr("id","svg")
    					//   .attr("width", width + margin.left + margin.right)
    					//   .attr("height", height + margin.top + margin.bottom)
    					// .append("g")
    					//   .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    				 //  svg.append("g")
    					//   .attr("class", "x axis")
    					//   .attr("transform", "translate(0," + height + ")")
    					//   .call(d3.axisBottom(xScale)); // Create an axis component with d3.axisBottom

    				 //  svg.append("g")
    					//   .attr("class", "y axis")
    					//   .call(d3.axisLeft(yScale)); // Create an axis component with d3.axisLeft

    				 //  svg.append("path")
    					//   .datum(element)
    					//   .attr("class", "line")
    					//   .attr("d", line);  
    			  }
    		});
		}
  }

  function get_nro_reads(fq,name){
    const path = require('path');
        var dir = document.getElementById(name).value;
        var file = path.join(dir , fq);

    if(!fs.existsSync(file+ "_stats.txt")) {

      if(fs.existsSync(file)){
      
        var fs = require('fs');
        var spawn = require('child_process').spawn;
        var cn = path.join(process.cwd(),'VD','bin','seqkit.exe ');
        var comando = spawn(cn,['stats','-p',file,'-o',file+"_stats.txt"],{shell:true}); console.log(comando);
        var str = fs.readFileSync(file+"_stats.txt", "utf8");
        var x = str.split('\n');
        var y = x[1].split('\t');
        y=y[3].replace(/,/g,"");

        return Number(y);
      }
    } else{

        var str = fs.readFileSync(file+"_stats.txt", "utf8");
        var x = str.split('\n');
        var y = x[1].split('\t');
        y=y[3].replace(/,/g,"");
        
        return Number(y);
    }
  }
  function spike(){
      if(document.getElementById("fileDialog").style.display == "none"){
        spike_analysis('ruta');
      } else{
        spike_analysis('fileDialog');
      }
  }

  function spike_analysis(dir,trim){
        const path = require('path');
        var fs = require('fs');
        var spawn = require('child_process').spawn;
        var cfiles = "";
        var cn = path.join(process.cwd(),'VD','bin','seqkit.exe ');
        var adapt = document.getElementById("spiketext").value;
        adapt = adapt.replace(/\n/g, ",");
 
        fs.readdir(dir, function(err, files) {
          
          if(trim){
            files.filter(extension_cleanfastq).forEach(function(value) {
                cfiles = path.join(dir , value); 
                var comando = spawn(cn,['locate','-p',adapt,cfiles,'-o',cfiles+".spike.txt"],{shell:true}); console.log(comando);
            }); 
          } else {
            files.filter(extension_fastq).forEach(function(value) {
                cfiles = path.join(dir , value); 
                var comando = spawn(cn,['locate','-p',adapt,cfiles,'-o',cfiles+".spike.txt"],{shell:true}); console.log(comando);
            }); 
          }

          if(cfiles != ""){
            document.getElementById("spiketext").disabled = true;
            // document.getElementById("run").style.display = "block";
            // document.getElementById("outputtext").style.display = "block";
          }

        });
      
        function extension(element) {
          var extName = path.extname(element);
          return extName === '.fq'; 
        };
        function extension_sRNA(element) {
              var extName = new RegExp('spike.txt$');
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

              // var svg = d3.select("#graph").append("svg")
              //   .attr("id","svg")
              //   .attr("width", width + margin.left + margin.right)
              //   .attr("height", height + margin.top + margin.bottom)
              // .append("g")
              //   .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

              // svg.append("g")
              //   .attr("class", "x axis")
              //   .attr("transform", "translate(0," + height + ")")
              //   .call(d3.axisBottom(xScale)); // Create an axis component with d3.axisBottom

              // svg.append("g")
              //   .attr("class", "y axis")
              //   .call(d3.axisLeft(yScale)); // Create an axis component with d3.axisLeft

              // svg.append("path")
              //   .datum(element)
              //   .attr("class", "line")
              //   .attr("d", line);  
            }
        });
      }
  }

  function control(name){

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
          value = value.replace(/_prot.pin/, "");
          select.options[select.options.length] = new Option(value, value);
        });
      });
      function extension(element) {
  	  var rege = new RegExp('_prot.pin$');
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

  function read_control(){

      const path = require('path');
      var dir = path.join(process.cwd(),'VD','databases');
      var fs = require('fs');

      fs.readdir(dir, function(err, files) {
        var select = document.getElementById("databases");
        files.filter(extension).forEach(function(value) {
          value = value.replace(/_prot.pin/, "");
          select.options[select.options.length] = new Option(value, value);
        });
      });
      function extension(element) {
      var rege = new RegExp('^c_');
        return rege.test(element); 
      };
  }

  function link_trimming(name){
    var path1 = document.getElementById(name).value;
    location.href = './clean.html?folder=' + path1;
  }

  function link_spike(name){
    var path1 = document.getElementById(name).value;
    location.href = './spike.html?folder=' + path1;
  }

  function link_analysis(name){
    var path1 = document.getElementById(name).value;
    location.href = './analysis.html?folder=' + path1;
  }

