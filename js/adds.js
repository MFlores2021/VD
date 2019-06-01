function update_db(orga,filt, vers){
	
    var org = document.getElementById(orga).value;
    var org1 = capitalize(org);
    var filter = document.getElementById(filt).value;
    var version = document.getElementById(vers).value;
    const path = require('path');

    var exec = require('child_process').exec;
    var execSync = require('child_process').execSync;
    var runperl = path.join("perlfiles","tmp_db.bat");
    var commrun = "perl " + path.join(process.cwd(),'VD','bin','download.pl '+ org1 + " " + filter+ " " + version);
    var info = "vrl_genbank_info.gz";
    var ids = "vrl_idmapping.gz";
	document.getElementById("running").innerHTML = "Downloading ...";
	document.getElementById("Update").style.display='none';

    create_analysisbat(runperl, commrun);

    exec(runperl, function(error,stdout,stderr){
        if(error!=null){
          console.log('error :', error);
          alert('Something went wrong. ' + error);
        } else{

          var database = path.join("VD","databases",stdout);
          try{
            var delPrev ="IF EXIST "+ path.join("VD","databases","vrl_*"+ org + "*" + filter + "*") + " DEL /F/Q/S " + path.join("VD","databases","vrl_*"+ org + "*" + filter + "*") + " >NUL";
            execSync(delPrev,  { stdio:  'inherit' } ); 
            var eje=execSync("IF EXIST "+ stdout + " move " + stdout + " "+ database,  { stdio:  'inherit' } ); 
            execSync("IF EXIST "+ info + " move " + info + " "+ path.join("VD","databases"),  { stdio:  'inherit' } ); 
            execSync("IF EXIST "+ ids + " move " + ids + " "+ path.join("VD","databases"),  { stdio:  'inherit' } ); 
            unzip_file(database);
            execSync("IF EXIST "+ database +" DEL /F/Q/S " + database + " >NUL",  { stdio:  'inherit' } );  
            execSync("IF EXIST "+ path.join("VD","databases","vrl_*amb") +" DEL /F/Q/S " + path.join("VD","databases","vrl_*amb") + " >NUL",  { stdio:  'inherit' } );  
            execSync("IF EXIST "+ path.join("VD","databases","vrl_*ann") +" DEL /F/Q/S " + path.join("VD","databases","vrl_*ann") + " >NUL",  { stdio:  'inherit' } );  
            execSync("IF EXIST "+ path.join("VD","databases","vrl_*pac") +" DEL /F/Q/S " + path.join("VD","databases","vrl_*pac") + " >NUL",  { stdio:  'inherit' } );         
          } catch (ex){
            console.log(ex);
          }
        }
       document.getElementById("running").innerHTML = "Done!";
    }); 
    var fs = require('fs');
    fs.readdir(path.join(process.cwd(),"VD","databases"), function(err, items) {
        items.filter(extension_vrl).forEach(function(value) {
          document.getElementById("currentv").value += value + "\n";
        });
    });	
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

function extension_result(element) {
  var extName = new RegExp('^result_');
  return extName.test(element); 
};

function extension_trim(element) {
  var extName = new RegExp('sRNA_length\\.txt$');
  return extName.test(element); 
};

function extension_spike(element) {
  var extName = new RegExp('spike\\.txt$');
  return extName.test(element); 
};


function extension_gz(element) {
  var extName = new RegExp('.\\.gz$');
  return extName.test(element); 
};

const capitalize = (s) => {
  if (typeof s !== 'string') return ''
  return s.charAt(0).toUpperCase() + s.slice(1)
}

function unzip(dir){

    console.log("unziping");
    const path = require('path');
    var fs = require('fs');
    var exec = require('child_process').execSync; 
    var tooldir = path.join(process.cwd(),'VD', 'bin','gzip.exe ');
	  var cfiles =""; 
    var files = fs.readdirSync(dir);

    files.filter(extension_gz).forEach(function(value) {
            
          cfiles = cfiles + path.join(dir , value) + " "; 
	 });
    
    if (cfiles != ""){
		  var commrun = tooldir  + " -d " + cfiles;

      exec(commrun, function(error,stdout,stderr){
          console.log(commrun);
          if(error!=null) console.log("unzip error:" + stderr);
      });
    }
}

function unzip_file(file){
  console.log("unziping");
    const path = require('path');
    var execSync = require('child_process').execSync; 
    var commrun = "tar -zxvf " + file + " --strip-components 1 -C " + path.join(process.cwd(),'VD','databases');

    var ff = execSync(commrun);
}
function zip_file(file,file2){
    const path = require('path');
    var execSync = require('child_process').execSync; 
	var tooldir = path.join(process.cwd(),'VD', 'bin','gzip.exe ');
    var commrun = tooldir + file + " " + file2;
    var ff = execSync(commrun);
}

