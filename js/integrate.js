/* integrate tools */
  function run_VD(name){
	
	var validation = validate();
	var fs = require('fs');
	const path = require('path');
	var dir = document.getElementById("pname").value;

	if (validation){
		document.getElementById("run").style.display='none';
		
		$('#ballsWaveG').show();
		upload(name);  
		var folder = document.getElementById("ruta").value; //'C:\\git\\VD\\results\\yora';
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

				setTimeout(save_html,10000,folder);
				setTimeout(alert,1000,"Done!");
				document.getElementById("container").style.display='none';
			});
			
		}
		$('#ballsWaveG').hide();
		//document.getElementById("run").style.display='block';
	}
}

  function validate(){
	if(!alphanumeric(document.getElementById("pname").value)) {
		alert("Please enter an alphanumber value as folder name. Do not use spaces.");
		return false;
	} else {
		if (document.getElementById("databases").value == ''){
			alert("Select a database.");
			return false;
		}
		
		var adaptor = document.getElementById("adaptor").value;
		if(document.getElementById("fileDialog").value != ''){ 
			if (adaptor != '' && document.getElementById("length").value != '' ){
				if(!alphabets(adaptor)){
					alert("Insert only ATGC adaptor");
					return false;
				} else {
					if (adaptor.length<15){
						alert('Adaptor sequence too short');
						return false;
					}
				}
			} else if (adaptor == '' && document.getElementById("length").value != ''){
				alert('Trimming: Provide both adaptor and length');
				return false;
			} else if(adaptor != '' && document.getElementById("length").value == ''){
				alert('Trimming: Provide both adaptor and length');
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
			alert('Select Fastq files to upload');
			return false;
		}
	}
	
}

//check perl and java4

