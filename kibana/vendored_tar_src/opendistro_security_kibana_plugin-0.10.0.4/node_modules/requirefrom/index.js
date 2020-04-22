/* 

Require from a directory relative to node_modules, flattening your require paths.

Example:
	Given project structure:
		node_modules/requirefrom/
		lib/some/complex/dir/module/module.js
		lib/otherModule/index.js

	The file module.js:
		var lib = require('requirefrom')('lib');
 		var otherModule = lib('otherModule');

	Would be equivalent to:
		var otherModule = require('../../../../otherModule');
*/

var path = require('path');


var requireFrom = module.exports = function requireFrom( fromPath ){
	return function requireModule( modulePath ){
		return require( path.normalize(
			__dirname + '/../../' + fromPath + '/' + modulePath
		) );
	}
}


// Extra feature. Add requireFrom: {"lib": "some/lib/dir/"}
// in package.json and then:
// var rf = require('requirefrom').readPkg();
// var module = rf.lib('myModule.js');
requireFrom.readPkg = function( prop ){
	var pkg, dirs, dir;

	prop = prop || 'requireFrom';

	try{ pkg = require(__dirname + '/../../package.json'); }
	catch(e){ throw new Error('requireFrom couldn\'t find package.json'); }

	dirs = pkg[prop];

	if(dirs){
		for(dir in dirs){
			requireFrom[dir] = requireFrom(dirs[dir]);
		}
	}

	return requireFrom;
};