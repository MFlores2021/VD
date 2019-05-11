/* integrate tools */

function run_all(name){

	var validation = validate();
	var fs = require('fs');

	if (validation){
		upload(name);
		var folder = document.getElementById("ruta").value;
		const clean =false;
		console.log("created folder" + folder);

		if (fs.existsSync(folder)) {
			unzip(folder);
			console.log("unzipped");
			run_fastqc(folder);
			console.log("fastqc ed");
			if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
				trimming(folder);
				clean = true;
				console.log("trimmed");
			}
			if(document.getElementById("inputtext").value != ''){
				spike_analysis(folder,clean);
				console.log("spiked");
			}
			//control(name);
			console.log("antes-ana");
			run_analysis(folder,clean);
			console.log("despues-ana");
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
			alert("Insert only ATGC for the adaptor");
			return false;
		}
	}
}

//check perl and java
