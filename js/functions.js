  function return_folder(){

    var dir = document.getElementById("pname").value;
    const path = require('path');
    var folder = path.join(process.cwd(),'results',dir);

    return folder;
  }

  function upload(name){

    var files = $(name)[0].files;
    const path = require('path');
    var fs = require('fs');
    var spawnSync = require('child_process').execSync;
    var exec = require('child_process').execSync;
    var dir = document.getElementById("pname").value;
    var pfolder = path.join(process.cwd(),'results',dir); 

    if (fs.existsSync(pfolder)) {
      alert('Folder name already exists, choose another folder name.');
    } else{
      
      var commitMessage = (function(){
        var spawn = spawnSync('md', [pfolder]);
        var errorText = spawn.error;
        if (errorText) {
          $('#ballsWaveG').hide();
          alert('Fatal error: Folder cannot be created!');
        }
        else {
          return spawn.stdout;
        }
      })();

      if (fs.existsSync(pfolder)) {
        
        document.getElementById("ruta").value = pfolder;
          console.log("sigue process");
        for (var i = 0; i < files.length; ++i){
            var tmp = files[i].name;
            // var newname1 = tmp.replace(".", "-");
            var newname = tmp.replace(" ", "-");

            exec("copy " + files[i].path + " "+  path.join(pfolder,newname) , function(error,stdout,stderr){
              // document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
              if(error!=null){
                $('#ballsWaveG').hide();
                alert('Something went wrong while copying files.' + error);
              } else{
                console.log("entra pfolder");
                
              }
            }); 
        }
      };
      
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
            alert("Error:" + error);
            return;
          } 
          alert("Done!");
        }); 
      }
    }
  }

  function upload_localdb(name,prot_name,info,ids,dir) {

   if (!($(prot_name)[0].value =="") && !($(name)[0].value =="" )){
      const path = require('path');
      var folder = path.join(process.cwd(),'VD',dir);
      var files = $(name)[0].files;
      var files_prot = $(prot_name)[0].files;
      var linfo = $(info)[0].files;
      var lids = $(ids)[0].files;
      var fs = require('fs');
      var exec = require('child_process').exec; 

      if (!fs.existsSync(folder)) {
        alert('Folder ' +dir+ ' does not exists');
      } else{
          for (var i = 0; i < files.length; ++i){ 
          var tmp = files[i].name;
          var tmp1 = tmp.replace(".fasta", "");
          var dbname  = "l_" +  tmp.replace(".fa", "");
          var commrun = "copy " + files[i].path + " "+ path.join(folder,dbname) +
             " & copy " + files_prot[i].path + " "+ path.join(folder,dbname + "_prot") +
             " & copy " + linfo[i].path + " "+ folder +
             " & copy " + lids[i].path + " "+ folder  ;
          
          exec(commrun, function(error,stdout,stderr){
            document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
            if(error!=null){
              alert('Error :', error);
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
      if(error!=null){
        alert('Error :', error);
      }
    }); 
  }
  
  function format_faidx(file){
    const path = require('path');
    var formatdb = path.join(process.cwd(),'VD','bin','samtools');
    var exec = require('child_process').exec; 
    var cmd = formatdb + " faidx " + file; console.log(cmd);

    exec(cmd, function(error,stdout,stderr){
      if(error!=null){
        alert('Error :', error);
      } 
    }); 
  }

  function run_fastqc(dir) {
    console.log("entra fastqc");
    const path = require('path');
    var fs = require('fs');
	  var fqcdir = path.join(process.cwd(),'VD', 'bin','fastQC');  
    var files = fs.readdirSync(dir);
    var cfiles =""; 
    
      files.filter(extension_fastq).forEach(function(value) {
          cfiles = cfiles + path.join(dir , value) + " "; 
      });

      if (cfiles != ""){
        var exec = require('child_process').execSync; 
  	    var commrun = "java -Xmx250m -classpath " + fqcdir + ";" + path.join(fqcdir,"sam-1.103.jar") + ";" + path.join(fqcdir,"jbzip2-0.9.jar") + " uk.ac.babraham.FastQC.FastQCApplication ";
  	   
        exec(commrun + cfiles, function(error,stdout,stderr){

          if(error!=null){ console.log(commrun);
            $('#ballsWaveG').hide();
            alert("Fastqc error:",error);
          }
        });

        var leftDiv = document.createElement("div"); 
        [].forEach.call(files, function (el) {
          var txt = "file://" + path.join(dir, path.parse(el).name) + "_fastqc.html";
          a = document.createElement('a');
          a.innerHTML = '<a target="_blank" href="' + txt + '" >' + el + '</a><br>';
          leftDiv.appendChild(a);
        });
      }
    
  }

  function run_analysis(dir,trim){

    const path = require('path');
    var fs = require('fs');
    var exec = require('child_process').exec; 
    var cfiles = "";
    var runperl = path.join("perlfiles","tmp.bat");
    var commrun = "perl " + path.join(process.cwd(),'VD','virus_detect.pl ');

    var files = fs.readdirSync(dir);
     
    if(trim){
      files.filter(extension_cleanfastq).forEach(function(value) {
        var stats1 = fs.statSync(path.join(dir , value)).size;console.log(stats1);
        if (stats1>50){
          cfiles = cfiles + path.join(dir , value) + " "; 
        }
      }); 
    }

    if(cfiles == ""){
      files.filter(extension_fastq).forEach(function(value) {
		    var stats1 = fs.statSync(path.join(dir , value)).size;
    		if (stats1>50){
    		  cfiles = cfiles + path.join(dir , value) + " "; 
    		}
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
          fs.writeFile(path.join(dir,"analysis.log"), commrun + "\n" + stdout, (err) => {   if (err) throw err; });

          if(error != null){
            $('#ballsWaveG').hide();
            alert('analysis error :', error); 
            fs.writeFile(path.join(dir,"analysis.log"), commrun + "\n" + error, (err) => {   if (err) throw err; });
            alert("There is an error. Please check analysis.log!");
            return;
          }
          alert("Done!");
        });
      }
    }
  }

  function run_trim(dir){

    const path = require('path');
    var fs = require('fs');
    var exec = require('child_process').exec; 
    var cfiles = "";
    var runperl = path.join("perlfiles","tmp2.bat");
	  var commrun = 'perl ' + path.join(process.cwd(),'VD','tools','sRNA_clean','sRNA_clean.pl ');

    var files = fs.readdirSync(dir);

    if(cfiles == ""){
      files.filter(extension_fastq).forEach(function(value) {
          cfiles = cfiles + path.join(dir , value) + " "; 
      }); 
    }

    if(cfiles != ""){
      var adapt = document.getElementById("adaptor").value;
      var len = document.getElementById("length").value;
      var commrun = commrun + ' -s '+ adapt + ' -l ' + len + ' ' + cfiles;

      commrun += cfiles; console.log(commrun);
      
      create_analysisbat(runperl, commrun);

      if(fs.existsSync(runperl)){
    		// exec(runperl); 
		
        exec(runperl, function(error,stdout,stderr){
          console.log('stdout :', stdout); 
		  
          fs.writeFile(path.join(dir,"analysis.log"), commrun + "\n" + stdout, (err) => {   if (err) throw err; });

          if(error != null){
            $('#ballsWaveG').hide();
            alert('Trimming error :', error); 
            fs.writeFile(path.join(dir,"analysis.log"), commrun + "\n" + error, (err) => {   if (err) throw err; });
            alert("There is an error. Please check analysis.log!");
            return;
          }

    		  run_analysis(dir,true);
    		  if(document.getElementById("spiketext").value != ''){
    			   spike_analysis(dir,true);
    		  }		  
        });
      }
    }
  }
  
  function trimming(dir){

    const path = require('path');
    var fs = require('fs');
    var spawn = require('child_process').spawn;
	   var exec = require('child_process').execSync;
    var cfiles = "";
    var cn = path.join(process.cwd(),'VD','tools','sRNA_clean','sRNA_clean.pl ');
    var runperl = path.join("perlfiles","tmp.bat");

    var files = fs.readdirSync(dir);

    files.filter(extension_fastq).forEach(function(value) {
        cfiles = cfiles + path.join(dir , value) + " "; 
    }); 
	
    if(cfiles != ""){
      console.log("FASTQ:", cfiles);
      var adapt = document.getElementById("adaptor").value;
      var len = document.getElementById("length").value;
      var commrun = 'perl ' + cn + ' -s '+ adapt + ' -l ' + len + ' ' + cfiles;

      create_analysisbat(runperl, commrun);
	  if(fs.existsSync(runperl)){
	
		exec(runperl, function(error,stdout,stderr){
			console.log('stdout :', stdout); 
            console.log('stderr :', stderr);
			console.log("get inside");
			if(error != null){
				console.log("ENTRA TRIM;", stderr);
			}
		});
/*       var comando = spawn(runperl,[],{shell:true});
      comando.stdout.on('data',(data) =>{ console.log('stdout:' + data);});
      comando.stderr.on('data',(data) =>{ console.log('trimming stderr:'+data);});
      comando.on('close',function(code){
       console.log("trimx after run_a code:", code);
      }); */
     console.log("termina trimming");
	  }
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


  function spike_analysis(dir,trim){

    const path = require('path');
    var fs = require('fs');
    var spawn = require('child_process').spawn;
    var cfiles = "";
    var cn = path.join(process.cwd(),'VD','bin','seqkit.exe ');
    var adapt = document.getElementById("spiketext").value;
        adapt = adapt.replace(/\n/g, ",");

    var files = fs.readdirSync(dir);
    
    if(trim){
      files.filter(extension_cleanfastq).forEach(function(value) {
		    var stats1 = fs.statSync(path.join(dir , value)).size;
        if (stats1>50){
          cfiles = path.join(dir , value); 
          var comando = spawn(cn,['locate','-p',adapt,cfiles,'-o',cfiles+".spike.txt"],{shell:true}); console.log(comando);
		    }
      }); 
    } 

  	if(cfiles == ""){
        files.filter(extension_fastq).forEach(function(value) {
      		var stats1 = fs.statSync(path.join(dir , value)).size;
      		if (stats1>50){
                cfiles = path.join(dir , value); 
                var comando = spawn(cn,['locate','-p',adapt,cfiles,'-o',cfiles+".spike.txt"],{shell:true}); console.log(comando);
      		}
        }); 
    }

    if(cfiles != ""){
        document.getElementById("spiketext").disabled = true;
    }
  }


  function control(name){

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

