/* integrate tools */
  function run_VD(name){
	
	var validation = validate();
	var fs = require('fs');
	const path = require('path');
	var dir = document.getElementById("pname").value;

	if (validation){
		document.getElementById("run").style.display='none';
		document.getElementById("running").innerHTML = "Running... Do not close the window until analysis is done.";
		
		upload(name);  
		var folder = document.getElementById("ruta").value;
		console.log("created folder:" + folder);

		if (fs.existsSync(folder)) {
			document.getElementById('outputtext').style.display = "block";
	        unzip(folder);
			var runperl = path.join("perlfiles","tmp.bat");
			var cn = path.join(process.cwd(),'perl','analysis.pl ');
			
			var spike = document.getElementById("spiketext").value;
				spike = spike.replace(/\n/g, ","); 
				spike = spike.replace(/,,/g, ",");
				spike = spike.replace(/,$/, ""); 
			var adaptor = document.getElementById("adaptor").value;
			var minlength = document.getElementById("minlength").value;
			var maxlength = document.getElementById("maxlength").value;
			var db = document.getElementById("databases").value;
			var ref = document.getElementById("references").value;
			var cores = document.getElementById("cores").value;
			var param = document.getElementById("param").value;
			var control = document.getElementById("control").value;
			var controlfile = document.getElementById("ccontrol").value;
			var controlconstant = document.getElementById("number_sd").value;
			var dedup = document.getElementById("dedup").checked;
			
			var commrun = 'perl ' + cn + ' '+ folder + " ";
			commrun = (spike.trim() != "") ? commrun + spike.toUpperCase() + " ": commrun + "NA ";
			commrun = (adaptor.trim() != "") ? commrun + adaptor.toUpperCase() + " ": commrun + "NA ";
			commrun = (minlength.trim() != "") ? commrun + minlength + " ": commrun + "NA ";
			commrun = (maxlength.trim() != "") ? commrun + maxlength + " ": commrun + "NA ";
			commrun = commrun + db + " ";
			commrun = (ref.trim() != "") ? commrun + ref + " ": commrun + "NA ";
			commrun = (cores.trim() != "") ? commrun + cores + " ": commrun + "NA ";
			commrun = (control.trim() != "") ? commrun + control + " ": commrun + "NA ";
			commrun = (controlfile.trim() != "") ? commrun + controlfile + " ": commrun + "NA ";
			commrun = (controlconstant.trim() != "") ? commrun + controlconstant + " ": commrun + "NA ";
			commrun = (dedup) ? commrun + dedup + " ": commrun + "NA ";
			commrun = (param.trim() != "") ? commrun + ' "'+ param + '" ' : commrun + "NA ";

			//hacer q si se elige control te pregunte la secuencia
	  
			create_analysisbat(runperl, commrun);

			console.log(runperl);

			const { spawn } =require("child_process");

			var analysis = spawn(runperl,{shell:true}, {windowsHide:true}); 

			analysis.stderr.on('data',(data) =>{ console.log('trimming stderr:'+data);});
			analysis.on('close',function(){ 

				document.getElementById("running").innerHTML = "Done!";
				document.getElementById("container").style.display='none';

			});
			document.getElementById("outputtext").style.visibility="visible";
			analysis.stdout.on('data', function(data) {
				 document.getElementById("outputtext").value += data.toString();
			});
		}
	}
}

  function validate(){
	if(!alphanumeric(document.getElementById("pname").value)) {
		document.getElementById("running").innerHTML = "Enter an alphanumeric folder name. Do not use spaces.";
		return false;
	} else {
		if (document.getElementById("databases").value == ''){
			document.getElementById("running").innerHTML = "Select a database.";
			return false;
		}
		
		var adaptor = document.getElementById("adaptor").value;
		if(document.getElementById("fileDialog").value != ''){ 
			if (adaptor != '' && document.getElementById("minlength").value != '' ){
				if(!alphabets(adaptor)){
					document.getElementById("running").innerHTML = "Insert only ATGC adaptor";
					return false;
				} else {
					if (adaptor.length<15){
						document.getElementById("running").innerHTML = 'Adaptor sequence too short';
						return false;
					}
				}
			} else if (adaptor == '' && document.getElementById("minlength").value != ''){
				document.getElementById("running").innerHTML = 'Trimming: Provide both adaptor and length';
				return false;
			} else if (adaptor != '' && document.getElementById("minlength").value == ''){
				document.getElementById("running").innerHTML = 'Trimming: Provide both adaptor and length';
				return false;
			} else if (adaptor == '' && document.getElementById("maxlength").value != ''){
				document.getElementById("running").innerHTML = 'Trimming: Provide both adaptor and length';
				return false;
			} else if (document.getElementById("minlength").value == '' && document.getElementById("maxlength").value != ''){
				document.getElementById("running").innerHTML = 'Trimming: Provide both min and max length';
				return false;
			}
/* 			if (document.getElementById("spiketext").value != ''){ 
				if(!alphabets(document.getElementById("spiketext").value)){
					alert("Insert only ATGC sequences.");
					return false;
				} 
			} */
			return true;
		} else {
			document.getElementById("running").innerHTML = 'Select Fastq files to upload';
			return false;
		}
	}
	
}

//check perl and java4

