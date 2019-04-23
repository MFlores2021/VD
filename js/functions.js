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
        var exec = require('child_process').exec; 
        var cfiles = "";
        var commrun = "perl " + path.join(process.cwd(),'VD','tools','sRNA_clean','sRNA_clean.pl ');
console.log(commrun);
        fs.readdir(dir, function(err, files) {
       
          files.filter(extension).forEach(function(value) {

              cfiles = cfiles + path.join(dir , value) + " "; 
          }); 

            if(cfiles != ""){

              commrun = (document.getElementById("adaptor").value != "") ?  commrun + " -s " + document.getElementById("adaptor").value + " " : commrun;
              commrun = (document.getElementById("length").value != "") ? commrun + " -l " + document.getElementById("length").value + " ": commrun;
              
              commrun += cfiles; 
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
