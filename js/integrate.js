/* integrate tools */

function run_all(folder){
	console.log("run_all");
	var validation = true; //validate();
	var fs = require('fs');

	if (validation){
		//upload(name); 
		//var folder = document.getElementById("ruta").value;
		const clean =false;
		//console.log("created folder" + folder);

		if (fs.existsSync(folder)) {
			//unzip(folder);
			console.log("creo folder");
			run_fastqc(folder);
			console.log("fastqc ed");
			if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
				trimming(folder);
				clean = true;
				console.log("trimmed");
			}
			if(document.getElementById("spiketext").value != ''){
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

function run_all1(name){
	console.log("run_all_1");
	var validation = true; //validate();
	var fs = require('fs');
	var files = $(name)[0].files;
    const path = require('path');
    var exec = require('child_process').exec; 
    var execgz = require('child_process').exec; 
    var folder = document.getElementById("pname").value;
    var dir = path.join(process.cwd(),'results',folder); 
    const clean =false;

    if (fs.existsSync(dir)) {
      alert('Folder name already exists, choose another folder name');
    } else{
      
	    exec('md ' + dir, function(error,stdout,stderr){ 
	        if(error!=null){ alert('error :', error); }
	        //else {
	          
		        for (var i = 0; i < files.length; ++i){
		              var tmp = files[i].name;
		              // var newname1 = tmp.replace(".", "-");
		              var newname = tmp.replace(" ", "-");

		              exec("copy " + files[i].path + " "+  path.join(dir,newname) , function(error,stdout,stderr){
		                // document.getElementById("subject").innerHTML += stdout +"\n" + stderr +"\n";
		                if(error!=null){
		                  console.log('error :', error);
		                  alert('Something went wrong while copying files. Error:' + error);
		                } else{
		                  document.getElementById("ruta").value = dir;
		                }
		             
				       var fs1 = require('fs');
		    		   var tooldir = path.join(process.cwd(),'VD', 'bin','gzip.exe ');
		    			console.log(dir);

					    fs1.readdir(dir, function(err, files) { 
					      files.filter(extension_gz).forEach(function(value) {
					        var cfiles ="";
					        cfiles = cfiles + path.join(dir , value) + " "; 
					        var commrun = tooldir  + " -d " + cfiles;

					        execgz(commrun, function(error,stdout,stderr){
						        if(error!=null) console.log("unzip error:" + stderr);
						    	if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
						    		trimmingx(dir);
						    	} else{
						    		if(document.getElementById("spiketext").value != ''){
						    			spike_analysis(folder,false);
						    		}
						    		run_analysis(dir,false);
						    	}
						    	run_fastqc(dir);
					        });
					      });
					    });
 					}); 
		        }
			    
			   //  fs.readdir(dir, function(err, files) {
			   //  	console.log("fastq & trimming");
				  //     var cfiles =""; 
				  //     files.filter(extension_fastq).forEach(function(value) {
				  //         cfiles = cfiles + path.join(dir , value) + " "; 
				  //     });
						// console.log(cfiles);

				  //   if (cfiles != ""){
				  //       var exec1 = require('child_process').exec; 
				  // 	    var commrun = "java -Xmx250m -classpath " + fqcdir + ";" + path.join(fqcdir,"sam-1.103.jar") + ";" + path.join(fqcdir,"jbzip2-0.9.jar") + " uk.ac.babraham.FastQC.FastQCApplication ";
				  	   
				  //       // exec1(commrun + cfiles, function(error,stdout,stderr){

				  //       //   if(error!=null){ console.log(commrun);
				  //       //     console.log("fastqc error:",error);
				  //       //   }
				  //       // });

				  //       /// Trimming
				  //       if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
					        
					 //        var spawn = require('child_process').spawn;
						//     var cn = path.join(process.cwd(),'VD','tools','sRNA_clean','sRNA_clean.pl ');
				  //       	var runperl = path.join("perlfiles","tmp.bat");
				  //           var adapt = document.getElementById("adaptor").value;
				  //           var len = document.getElementById("length").value;
				  //           var commrun1 = 'perl ' + cn + ' -s '+ adapt + ' -l ' + len + ' ' + cfiles;

				  //           create_analysisbat(runperl, commrun1);

			   //    			  // // var comando = spawn('perl',[cn,'-s',adapt,'-l',len,cfiles],{shell:true});
					 //           //    var comando = spawn(runperl,[],{shell:true});
					 //           //    comando.stdout.on('data',(data) =>{ console.log('stdout: ${data}');});
			   //    			  // comando.stderr.on('data',(data) =>{ console.log('trimming stderr: ${data}');});
			   //    			  // comando.on('close',function(code){
			   //    				 //  if(code === 0){
			   //    					// dibujo(fs,dir);
			   //    				 //  }
			   //    				clean = true;
			   //    			  // })
			   //    		}
			   //    	}
			   //  });
		    //   		if(clean){
					 //    fs.readdir(dir, function(err, files) {
					 //       var cfiles =""; 
					 //        files.filter(extension_cleanfastq).forEach(function(value) {
					 //            cfiles = cfiles + path.join(dir , value) + " "; 
					 //        }); 
					 //    });
				  //   } else {
				  //   	fs.readdir(dir, function(err, files) {
						//       var cfiles =""; 
						//       files.filter(extension_fastq).forEach(function(value) {
						//           cfiles = cfiles + path.join(dir , value) + " "; 
						//       });
						// });
				  //   }

		    //   		///Spiking      		
		    //   		if(document.getElementById("spiketext").value != ''){
		    //   			var spawn2 = require('child_process').spawn;
				  //       var cn2 = path.join(process.cwd(),'VD','bin','seqkit.exe ');
				  //       var adapt2 = document.getElementById("spiketext").value;
				  //       adapt2 = adapt2.replace(/\n/g, ",");
				 
				          
				  //         if(clean){
				  //         	cfiles = "";
				  //           files.filter(extension_cleanfastq).forEach(function(value) {
				  //               cfiles = path.join(dir , value); 
				  //               var comando2 = spawn2(cn2,['locate','-p',adapt2,cfiles,'-o',cfiles+".spike.txt"],{shell:true}); console.log(comando);
				  //           }); 
				  //         } else {
				  //           files.filter(extension_fastq).forEach(function(value) {
				  //               cfiles = path.join(dir , value); 
				  //               var comando2 = spawn2(cn2,['locate','-p',adapt2,cfiles,'-o',cfiles+".spike.txt"],{shell:true}); console.log(comando);
				  //           }); 
				  //         }

				  //         if(cfiles != ""){
				  //           document.getElementById("spiketext").disabled = true;
				  //         }
		    //   		}

		    //   		//run analysis
				  //   var exec2 = require('child_process').exec; 
				  //   var runperl2 = path.join("perlfiles","tmp.bat");
				  //   var commrun3 = "perl " + path.join(process.cwd(),'VD','virus_detect.pl ');

				   

				  //   if(cfiles != ""){
				  //   	console.log("entra_analysis");
				  //       var db1 = document.getElementById("databases").value;
				  //       var db = db1.replace(".nin", "");
				  // 		var ref = document.getElementById("references").value;
				  // 		var cores = document.getElementById("cores").value;
				  //       commrun3 = (db != "") ?  commrun3 + " --reference " + db + " " : commrun3;
				  //       commrun3= (ref != "") ? commrun3 + " --host_reference " + ref + " ": commrun3;
				  //       commrun3 = (cores != "") ? commrun3 + " --thread_num " + cores + " ": commrun3;
				        
				  //       commrun3 += cfiles; console.log(commrun3);
				        
				  //       create_analysisbat(runperl2, commrun3);

				  //       if(fs.existsSync(runperl2)){

				  //           exec2(runperl2, function(error,stdout,stderr){
				  //             console.log('stdout :', stdout); 
				  //             console.log('stderr :', stderr); 
				  //             fs.writeFile(path.join(dir,"analysis.log"), commrun3 + "\n" + stdout, (err) => {   if (err) throw err; });

				  //             if(error != null){
				  //               console.log('analysis error :', error); 
				  //               fs.writeFile(path.join(dir,"analysis.log"), commrun3 + "\n" + error, (err) => {   if (err) throw err; });
				  //               alert("There is an error in the analysis. Please check analysis.log!");
				  //               return;
				  //             }
				  //             alert("Done!");
				  //           });
				  //        }

				  //   }

		/// end
			    //}	
		    //}
      	});

		function extension_gz(element) {
		  var extName = new RegExp('\\.gz$');
		  return extName.test(element); 
		};
    }


	if (validation){
		//upload(name); 
		//var folder = document.getElementById("ruta").value;
		const clean =false;
		//console.log("created folder" + folder);

		if (fs.existsSync(folder)) {
			//unzip(folder);
			console.log("creo folder");
			run_fastqc(folder);
			console.log("fastqc ed");
			if (document.getElementById("adaptor").value != '' && document.getElementById("length").value != ''){
				trimming(folder);
				clean = true;
				console.log("trimmed");
			}
			if(document.getElementById("spiketext").value != ''){
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
