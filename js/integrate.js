/* integrate tools */

function run_all(name){

	var validation = validate();

	if (validation){
		upload(name);
		var folder = document.getElementById("ruta").value;
		const clean =false;

		if (fs.existsSync(folder)) {
			unzip(folder);
			run_fastqc(folder);
			if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
				trimming(folder);
				clean = true;
			}
			if(document.getElementById("inputtext").value != ''){
				spike_analysis(folder,clean);
			}
			//control(name);
			run_analysis(folder,clean);
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
