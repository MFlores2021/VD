
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
        var spawn = spawnSync('md ' +pfolder);
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

  function upload_control(name,dir) {

    const path = require('path');
    var folder = path.join(process.cwd(),'VD',dir);
    var files = $(name)[0].files;
    var fs = require('fs');
    var exec = require('child_process').exec; 

    if (!fs.existsSync(folder)) {
      alert('Folder ' +dir+ ' does not exists');
    } else{
        for (var i = 0; i < files.length; ++i){
        exec("copy " + files[i].path + " "+ path.join(folder,"c_"+files[i].name), function(error,stdout,stderr){
          if(error!=null){
            alert("Error:" + error);
            return;
          } 
          format_faidx(path.join(folder,"control_"+files[i].name));
          alert("Done!");
        }); 
      }
    }
  }

  function upload_localdb(name,prot_name,dir,info,ids) {

   if (!($(prot_name)[0].value =="") && !($(name)[0].value =="" ) && !($(info)[0].value =="" ) && !($(ids)[0].value =="" )){
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
      } else {
          for (var i = 0; i < files.length; ++i){ 
          var tmp = files[i].name;
          var tmp1 = tmp.replace(".fasta", "");
          var dbname  = "l_" +  tmp1.replace(".fa", "");
		      var db = path.join(folder,dbname);
          var commrun = "copy " + files[i].path + " "+ db +
             " & copy " + files_prot[i].path + " "+ db + "_prot" +
             " & copy " + linfo[i].path + " "+ db + "_genbank_info" +
             " & copy " + lids[i].path + " "+ db + "_idmapping";
          
          exec(commrun, function(error,stdout,stderr){
            document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
            if(error!=null){
              alert('Error :', error);
            } 
			  if (dir == 'databases'){
					format_db(db,"nucl");
					format_db(db + "_prot","prot");
					format_faidx(db);
					zip_file(db + "_genbank_info",db + "_idmapping");
			  }
			   document.getElementById("subject").innerHTML = "Done!\n";
		   }); 
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
        console.log('Error :', error);console.log('Error :', stderr);
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
		var rege = new RegExp('^host_.+nin');
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
          select.options[select.options.length] = new Option(value, value);
        });
      });
      function extension(element) {
      var rege = new RegExp('^control_.+fa|^control_.+fasta');
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

  function check_java(){
	  
	  const path = require('path');
	  var fqcdir = path.join(process.cwd(),'VD', 'bin','fastQC');  
      var exec = require('child_process').exec;
  	  var commrun = "java -Xmx250m -classpath " + fqcdir + ";" + path.join(fqcdir,"sam-1.103.jar") + ";" + path.join(fqcdir,"jbzip2-0.9.jar") + " uk.ac.babraham.FastQC.FastQCApplication --help";
  	  
      exec(commrun , function(error,stdout,stderr){
        if(error!=null){
            alert("Check your Java installation",error);
        } 
      });
  }
	
	function check_perl(){
		let fs = require('fs');
		let path = require('path');
		let dir = path.join(process.cwd(),'perlfiles'); 
		if(!fs.existsSync(dir)){
			alert("Perl libraries error.\nMake sure perlfiles directory exists.");
		} 
	}