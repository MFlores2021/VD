/* integrate tools */

  function run_all(name){
	
	var validation = true; //validate();
	var fs = require('fs');

	if (validation){
		$('#ballsWaveG').show();
		upload(name); 
		var folder = document.getElementById("ruta").value;
		var clean =false;
		console.log("created folder:" + folder);

		if (fs.existsSync(folder)) {
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
	$('#ballsWaveG').hide();
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
			alert("Insert only ATGC for the adaptor");
			return false;
		}
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
