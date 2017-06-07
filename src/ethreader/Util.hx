package ethreader;

import js.node.Fs;

class Util{

	static public function ensureFolderExists(folder : String) : Void{
		if (!Fs.existsSync(folder)){
			Fs.mkdirSync(folder);
		}
	}

	static public function saveToFile(filename : String, data : String, callback : Error -> Void){
		Fs.writeFile(filename, data, function(err) {
			callback(err);
		}); 
	}

	static public function getFromFile(filename : String, callback : Error -> String -> Void){
		Fs.readFile(filename,  function(err,result){
			if(err != null){
				callback(err, null);
			}else if(result.toString() == ""){
				callback("nothing", null);
			}else{
				callback(err, result.toString());
			}
		});
	}

	
}