// Test requireFrom. Simple test with no dependencies.

var fs = require('fs');

var src  = __dirname + '/../index.js'
var dest = __dirname + '/node_modules/requirefrom/index.js';



// We'll need requirefrom in the node_modules directory
copyFile( src, dest
	, function(err){
		if(err){ 
			console.log('Could not copy requirefrom into the test directory.');
			console.log(err);
		}
		else{
			runTest();
		}

		// Cleanup
		fs.unlink(dest);
	}
);




function runTest(){
	var
	    rf = require('requirefrom')
	  , views = rf('lib/components/framework/views/')
	  , models = rf('lib/components/framework/models/')
	  , utility = rf('lib/utility/')

	  , loginForm = views('login.js')
	  , signupForm = views('signup.js')
	  , userModel = models('user')
	  , normalizeUser = utility('normalize/user.js');

	var result = JSON.stringify([loginForm, signupForm, userModel, normalizeUser]);

	var shouldBe = JSON.stringify([
		  require('./lib/components/framework/views/login.js')
		, require('./lib/components/framework/views/signup.js')
		, require('./lib/components/framework/models/user')
		, require('./lib/utility/normalize/user.js')
	]);



	if(result === shouldBe)
		console.log('Test 1 Passed');
	else
		console.log(
			'Test 1 Failed\n\n\tResult: \n\t\t%s\n\n\tShould have been: \n\t\t%s'
			, result, shouldBe
		);



	rf.readPkg();

	loginForm = rf.views('login.js');
	signupForm = rf.views('signup.js');
	userModel = rf.models('user');
	normalizeUser = rf.utility('normalize/user.js');

	result = JSON.stringify([loginForm, signupForm, userModel, normalizeUser]);

	if(result === shouldBe)
		console.log('Test 2 Passed');
	else
		console.log(
			'Test 2 Failed\n\n\tResult: \n\t\t%s\n\n\tShould have been: \n\t\t%s'
			, result, shouldBe
		);

}





// Thanks: http://stackoverflow.com/questions/11293857/fastest-way-to-copy-file-in-node-js/14387791#14387791
function copyFile(source, target, cb){
	var cbCalled = false;

	var rd = fs.createReadStream(source);
	rd.on("error", function(err){
		done(err);
	});

	var wr = fs.createWriteStream(target);
	wr.on("error", function(err){
		done(err);
	});
	wr.on("close", function(ex){
		done();
	});
	
	rd.pipe(wr);

	function done(err){
		if(!cbCalled){
			cb(err);
			cbCalled = true;
		}
	}
}
