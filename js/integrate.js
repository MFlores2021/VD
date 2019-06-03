/* integrate tools */
  function run_VD(name){
	
	var validation = validate();
	var fs = require('fs');
	const path = require('path');
	var dir = document.getElementById("pname").value;

	if (validation){
		document.getElementById("run").style.display='none';
		document.getElementById("running").innerHTML = "Running ...";
		
		upload(name);  
		var folder = document.getElementById("ruta").value;
		console.log("created folder:" + folder);

		if (fs.existsSync(folder)) {

	        unzip(folder);
			var runperl = path.join("perlfiles","tmp.bat");
			var cn = path.join(process.cwd(),'perl','analysis.pl ');
			
			var spike = document.getElementById("spiketext").value;
				spike = spike.replace(/\n/g, ","); 
				spike = spike.replace(/,,/g, ",");
				spike = spike.replace(/,$/, ""); 
			var adaptor = document.getElementById("adaptor").value;
			var length = document.getElementById("length").value;
			var db = document.getElementById("databases").value;
			var ref = document.getElementById("references").value;
			var cores = document.getElementById("cores").value;
			var param = document.getElementById("param").value;
			var control = document.getElementById("control").value;
			
			var commrun = 'perl ' + cn + ' '+ folder + " ";
			commrun = (spike.trim() != "") ? commrun + spike.toUpperCase() + " ": commrun + "NA ";
			commrun = (adaptor.trim() != "") ? commrun + adaptor.toUpperCase() + " ": commrun + "NA ";
			commrun = (length.trim() != "") ? commrun + length + " ": commrun + "NA ";
			commrun = commrun + db + " ";
			commrun = (ref.trim() != "") ? commrun + ref + " ": commrun + "NA ";
			commrun = (cores.trim() != "") ? commrun + cores + " ": commrun + "NA ";
			commrun = (control.trim() != "") ? commrun + control + " ": commrun + "NA ";
			commrun = (param.trim() != "") ? commrun + ' "'+ param + '" ' : commrun + "NA ";
	  
			create_analysisbat(runperl, commrun);

			console.log(runperl);

			const { spawn } =require("child_process");
			//var analysis = spawn("ls ",{shell:true}, {windowsHide:true}); 
			var analysis = spawn(runperl,{shell:true}, {windowsHide:true}); 
			//analysis.stdout.on('data',(data) =>{ console.log('stdout:' + data);});
			analysis.stderr.on('data',(data) =>{ console.log('trimming stderr:'+data);});
			analysis.on('close',function(){ 
			    var fs1 = require('fs');
				var files = fs1.readdirSync(folder);
				const path1 = require('path');

				var filesTrim =""; 
				var filesspike ="";
				document.getElementById("graph").innerHTML='<h2 align=center>Sequence lenght distribution after trimming</h2>';
				files.filter(extension_trim).forEach(function(value) {
					filesTrim = path1.join("results",dir,value); 
					draw_sRNA_summary(filesTrim,value);
				});
				document.getElementById("graph1").innerHTML='<h2 align=center><br>Spike frequency</h2>';
				files.filter(extension_spike).forEach(function(value) {
					filesspike = path1.join("results",dir,value);
					draw_spike_summary(filesspike,value);
				}); 

				setTimeout(save_html,100,folder); 
				setTimeout(merge,1000);
				setTimeout(del,5000);
				document.getElementById("running").innerHTML = "Done!";
				
				function merge(){
					var mergehtml = "type "+ path.join(folder,"*1html") +" >>"+path.join(folder,"result.html");
					var analysis1 = spawn(mergehtml,{shell:true}, {windowsHide:true});
				}
				function del(){
					var fs2 = require('fs');
					fs2.readdir(folder, function(err, files) {
						files.filter(extensionhtml).forEach(function(value) {
							fs2.unlinkSync(path.join(folder,value)); console.log(value);
						});
					});
				}					
				document.getElementById("container").style.display='none';

			});
			
			function extensionhtml(element) {
				  var rege = new RegExp('\.1html$');
					return rege.test(element); 
			};
		}
		
		//document.getElementById("run").style.display='block';
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
			if (adaptor != '' && document.getElementById("length").value != '' ){
				if(!alphabets(adaptor)){
					document.getElementById("running").innerHTML = "Insert only ATGC adaptor";
					return false;
				} else {
					if (adaptor.length<15){
						document.getElementById("running").innerHTML = 'Adaptor sequence too short';
						return false;
					}
				}
			} else if (adaptor == '' && document.getElementById("length").value != ''){
				document.getElementById("running").innerHTML = 'Trimming: Provide both adaptor and length';
				return false;
			} else if(adaptor != '' && document.getElementById("length").value == ''){
				document.getElementById("running").innerHTML = 'Trimming: Provide both adaptor and length';
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

