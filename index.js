// Define modules/config
var express = require('express'),
    app = express();

// Run Coffeescript
require('coffee-script/register');

// Realtime Client
socket = require('./realtime');

// Device controller
devices = require('./lib/devices/controller');

// Interface
require('./lib/interface')(devices, socket);

/*
//Setup express
app.use(express.static(__dirname + '/static'));

//Start server
app.listen(3000);

console.log('Node ' + config.server + ' server running on port 3000');
*/