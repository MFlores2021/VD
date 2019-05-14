function update_db(){
console.log("err0");
  var Client = require('ftp');
var fs = require('fs');

// var req = http.get('ftp://bioinfo.bti.cornell.edu/pub/program/VirusDetect/virus_database/v229/U100/protozoa_229_U100.tar.gz', function (res) {

//     var fileSize = res.headers['content-length'];
//     res.setEncoding('binary');
//     var a = "";
//     res.on('data', function (chunk) {
//         a += chunk;
//         document.getElementById('percent').innerHTML = Math.round(100*a.length/fileSize) + "";
//     });
//     res.on('end', function() {
//         fs.writeFile('file.tar.gz', a, 'binary', function (err) {
//             if (err) throw err;
//             console.log('finished');
//         });
//     });
// });

// }
//  host: "ftp://bioinfo.bti.cornell.edu/pub/program/VirusDetect/virus_database/v229/U100/",
// var connectionProperties = {
//     host: "ftp://bioinfo.bti.cornell.edu"
// };

  var c = new Client();
  c.on('ready', function() { console.log("err1");
    c.get('protozoa_229_U100.tar.gz', function(err, stream) {
      if (err) console.log(err);
      console.log("err");
      stream.once('close', function() { c.end(); });
      stream.pipe(fs.createWriteStream('file.tar.gz'));
    });
  });
  // connect to localhost:21 as anonymous
  c.connect(connectionProperties);

}

function create_analysisbat(file, commrun){

    const fs = require('fs');

    var perlexport = '@echo off\n\n' +
    'if not "%1" == "/SETENV" setlocal\n\n' +
    'set PATH=%~dp0perl\\site\\bin;%~dp0perl\\bin;%~dp0c\\bin;%PATH%\n\n' +
    'set TERM=\n' +
    'set PERL_JSON_BACKEND=\n' +
    'set PERL_YAML_BACKEND=\n' +
    'set PERL5LIB=\n' +
    'set PERL5OPT=\n' +
    'set PERL_MM_OPT=\n' +
    'set PERL_MB_OPT=\n\n' +
    'if "%1" == "/SETENV" goto END\n\n' +
    'if not "%1" == "" "%~dp0perl\\bin\\perl.exe" %* & goto ENDLOCAL\n\n' +
    'if ERRORLEVEL==1 echo FATAL ERROR: perl does not work; check if your strawberry pack is complete!\n\n' +
    commrun + '\n\n' +
    ':ENDLOCAL\n\n' +
    'endlocal\n\n' +
    ':END\n' ;

    fs.writeFile(file, perlexport, (err) => {  
        if (err){ 
          throw err;
          return false;
        }
        return true;
    });
}


function removeElement(elementId) {
    // Removes an element from the document
    var element = document.getElementById(elementId);
    element.parentNode.removeChild(element);
}


  function onlyNos(e, t) {
      try {
          if (window.event) {
              var charCode = window.event.keyCode;
          }
          else if (e) {
              var charCode = e.which;
          }
          else { return true; }
          if (charCode > 31 && (charCode < 48 || charCode > 57)) {
              return false;
          }
          return true;
      }
      catch (err) {
          alert(err.Description);
      }
  } 

  function onlyAlphabets(e, t) {
    try {
        if (window.event) {
            var charCode = window.event.keyCode;
        }
        else if (e) {
            var charCode = e.which;
        }
        else { return true; }
        if ((charCode > 64 && charCode < 91) || (charCode > 96 && charCode < 123) ||  charCode == 13)
            return true;
        else
            return false;
    }
    catch (err) {
        alert(err.Description);
    }
} 

function alphanumeric(string){

  var check = /^[0-9a-zA-Z]+$/;
  if(string.match(check)) return true;
  else return false; 
}

function alphabets(string){

  var check = /^[a-zA-Z]+$/;
  if(string.match(check)) return true;
  else return false; 
}

function extension_fastq(element) {
  var extName = new RegExp('.\\.fastq$|.\\.fq$');
  return extName.test(element); 
};

function extension_cleanfastq(element) {
  var extName = new RegExp('clean\\.fastq$|clean\\.fq$');
  return extName.test(element); 
};

function extension_gz(element) {
  var extName = new RegExp('.\\.gz$');
  return extName.test(element); 
};


function unzip(dir){
  console.log("unziping");
    const path = require('path');
    var fs = require('fs');
    var exec = require('child_process').exec; 
    var tooldir = path.join(process.cwd(),'VD', 'bin','gzip.exe ');

    var files = fs.readdirSync(dir);
      files.filter(extension_gz).forEach(function(value) {
        var cfiles ="";
        
        for (var i = 0; i < files.length; ++i){
          cfiles = cfiles + path.join(dir , files[i]) + " "; 
        }
        var commrun = tooldir  + " -d " + cfiles;

        exec(commrun, function(error,stdout,stderr){
          console.log(commrun);
          if(error!=null) console.log("unzip error:" + stderr);
        });
      });

}

