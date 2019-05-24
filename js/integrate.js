/* integrate tools */
  function run_VD(name){
	
	var validation = true; // validate();
	var fs = require('fs');
	const path = require('path');
	var execSync = require('child_process').execSync;
	var spawnSync = require('child_process').spawnSync;
	var spawn1 = require('child_process').spawn;

	if (validation){
		//$('#ballsWaveG').show();
		//upload(name);  
		var folder = "c:\\git\\VD\\results\\tyutyu"; //document.getElementById("ruta").value;
		console.log("created folder:" + folder);

		if (fs.existsSync(folder)) {

	        unzip(folder);
			var runperl = path.join("perlfiles","tmp.bat");
			var cn = path.join(process.cwd(),'perl','analysis.pl ');
			
			var spike = document.getElementById("spiketext").value;
				spike = spike.replace(/\n/g, ",");
			var adaptor = document.getElementById("adaptor").value;
			var length = document.getElementById("length").value;
			var db = document.getElementById("databases").value;
			var ref = document.getElementById("references").value;
			var cores = document.getElementById("cores").value;
			var param = document.getElementById("param").value;
			
			var commrun = 'perl ' + cn + ' '+ folder + " ";
			commrun = (spike != "") ? commrun + spike + " ": commrun + "NA ";
			commrun = (adaptor != "") ? commrun + adaptor + " ": commrun + "NA ";
			commrun = (length != "") ? commrun + length + " ": commrun + "NA ";
			commrun = commrun + db + " ";
			commrun = (ref != "") ? commrun + ref + " ": commrun + "NA ";
			commrun = (cores != "") ? commrun + cores + " ": commrun + "NA ";
			commrun = (param != "") ? commrun + param + " ": commrun + "NA ";
	  
			create_analysisbat(runperl, commrun);

			console.log(runperl);

			const { spawn } =require("child_process");
			//var analysis = spawn(runperl,{shell:true}, {windowsHide:true}); 
			var analysis = spawn("dir",{shell:true}, {windowsHide:true});
			analysis.stdout.on('data',(data) =>{ console.log('stdout:' + data);});
			analysis.stderr.on('data',(data) =>{ console.log('trimming stderr:'+data);});
			analysis.on('close',function(code){
			   console.log("poner algo:", code);
			    var fs1 = require('fs');
				var files = fs1.readdirSync(folder);
				const path1 = require('path');console.log(files);

				var filesTrim =""; 
				var filesspike ="";
				files.filter(extension_trim).forEach(function(value) {
					filesTrim = path1.join(folder,value); console.log("rna:",value);
				});
				files.filter(extension_spike).forEach(function(value) {
					filesspike = path1.join(folder,value);console.log("spike:",value);
				}); 
				draw_summary(filesTrim,filesspike);

				alert('Done ! Check your results!');
			});
		
			console.log("paso");
			
		    //$('#ballsWaveG').hide();
			/* 
			save_html(folder); */
		}

	}
	
}

  function run_all(name){
	
	var validation = validate();
	var fs = require('fs');
	const path = require('path');
	var execSync = require('child_process').execSync;

	if (validation){
		//$('#ballsWaveG').show();
		upload(name);  
		var folder = document.getElementById("ruta").value;
		var clean =false;
		console.log("created folder:" + folder);

		if (fs.existsSync(folder)) {
			execSync("IF EXIST "+ path.join("VD","databases","vrl_*amb") +" DEL /F/Q/S " + path.join("VD","databases","vrl_*amb") + " >NUL",  { stdio:  'inherit' } );  
	        execSync("IF EXIST "+ path.join("VD","databases","vrl_*ann") +" DEL /F/Q/S " + path.join("VD","databases","vrl_*ann") + " >NUL",  { stdio:  'inherit' } );  
	        execSync("IF EXIST "+ path.join("VD","databases","vrl_*pac") +" DEL /F/Q/S " + path.join("VD","databases","vrl_*pac") + " >NUL",  { stdio:  'inherit' } );   
	        unzip(folder);
			console.log("creo folder");
			run_fastqc(folder);
			console.log("fastqc ed");
			if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
				run_trim(folder);
				clean = true;
				console.log("trimmed");
			} else{
				if(document.getElementById("spiketext").value != ''){
					spike_analysis(folder,clean);
				}
				//control(name);
				run_analysis(folder,clean);
			}
		}

	}
	
}

function validate(){
	if(!alphanumeric(document.getElementById("pname").value)) {
		alert("Please enter an alphanumber value for folder. Do not use spaces.");
		return false;
	} else {
		var adaptor = document.getElementById("adaptor").value;
		if(document.getElementById("fileDialog").value != ''){
			if (adaptor != '' && document.getElementById("length").value != '' ){
				if(!alphabets(adaptor)){
					alert("Insert only ATGC for the adaptor");
					return false;
				} else {
					if (adaptor.length<15){
						alert('Adaptor sequence too short');
						return false;
					} else return true;
				}
			} else if (adaptor == '' && document.getElementById("length").value != ''){
				alert('Trimming: Provide both adaptor and length');
				return false;
			} else if (adaptor != '' && document.getElementById("length").value == ''){
				alert('Trimming: Provide both adaptor and length');
				return false;
			} else {
				return true;
			}
		} else {
			alert('Select Fastq files to upload');
			return false;
		}
	}
	if (document.getElementById("inputtext").value != ''){
		if(!alphabets(document.getElementById("spike").value)){
			alert("Insert only ATGC sequences.");
			return false;
		}
	}

	if (document.getElementById("databases").value != ''){
		alert("Select a database.");
		return false;
	}	
}

//check perl and java

function execShellCommand(cmd) {
 const exec = require('child_process').exec;
 return new Promise((resolve, reject) => {
  exec(cmd, (error, stdout, stderr) => {
   if (error) {
    console.warn(error);
   }
   resolve(stdout? stdout : stderr);
  });
 });
}
