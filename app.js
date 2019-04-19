var port = process.env.PORT || 8080,
    http = require('http'),
    fs = require('fs'),
	os = require('os'),
	path = require('path'),
	urlModule = require('url'),
	dttags = process.env.DT_TAGS || "<EMPTY>",
	dtcustprops = process.env.DT_CUSTOM_PROP || "<EMPTY>",
	dtclusterid = process.env.DT_CLUSTER_ID || "<EMPTY>",
    html = fs.readFileSync(__dirname + '/index.html').toString().replace("HOSTNAME", os.hostname() + " with DT_TAGS=" + dttags + "\nDT_CUSTOM_PROP=" + dtcustprops + "\nDT_CLUSTER_ID=" + dtclusterid);

// ======================================================================
// Here are some global config entries that change the behavior of the app
// ======================================================================
var problemNumber = 1;
var minSleep = 500;
var requestCount = 0;
var inProduction = false;
var invokeRequestCount = 0;
var failInvokeRequestPercentage = 0;

// ======================================================================
// does some init checks and sets variables!
// ======================================================================
var init = function(newProblemNumber) {
	// CHECK IF WE ARE RUNNING "In Production"
	inProduction = process.env.DEPLOYMENT_GROUP_NAME && process.env.DEPLOYMENT_GROUP_NAME.startsWith("Production");
	
	if(inProduction) {
		environmentName = "Production";
		minSleep = 300; // we just simulate that production is a bit faster than staging, e.g: better hardware!
	}
	else {
		environmentName = "Staging";
	}

	// here are some "problems" we simulate for different problems. Problems are identified via Env Variable PROBLEM_NUMBER;
	// problem # | Problem
	// 1 | no problem
	// 2 | 50% of requests return HTTP 500 Status Code
	// 3 | back to normal
	// 4 | no problem in staging but problem in prod -> higher sleep time and 10% of requests fail
	// X | any other problem number will run like 1 & 3
	if(newProblemNumber != null) {
		problemNumber = parseInt(newProblemNumber);
	}
	else if(process.env.PROBLEM_NUMBER && process.env.PROBLEM_NUMBER != null) {
		problemNumber = parseInt(process.env.PROBLEM_NUMBER);
    }

	switch(problemNumber) {
		case 2:
			failInvokeRequestPercentage = 2;
			break;
		case 4: 
			if(inProduction) {
				minSleep = minSleep * 2;
				failInvokeRequestPercentage = 10;
			}
			break;
		default:
			// everything normal here
			failInvokeRequestPercentage = 0;		
			break;
	}

	console.log("Init: " + problemNumber + "/" + failInvokeRequestPercentage);
} 

// ======================================================================
// Background colors for our app depending on the problem
// ======================================================================
var backgroundColors = ["#EEA53E", "#73A53E", "#FF0000", "#FFFF00", "#777777"]
var getBackgroundColor = function() {
	var problemNumberForBackgroundColor = problemNumber;
	if(problemNumber == 0 || problemNumber > 4) problemNumberForBackgroundColor = 1;
	
	return backgroundColors[problemNumberForBackgroundColor];
}

// ======================================================================
// This is for logging
// ======================================================================
var logstream = fs.createWriteStream('./serviceoutput.log');
var SEVERITY_DEBUG = "Debug";
var SEVERITY_INFO = "Info";
var SEVERITY_WARNING = "Warning";
var SEVERITY_ERROR = "Error";

var log = function(severity, entry) {
	// console.log(entry);
	if (severity === SEVERITY_DEBUG) {
		// dont log debug
	} else {
		var logEntry = new Date().toISOString() + ' - ' + severity + " - " + entry + '\n';
		// fs.appendFileSync('./serviceoutput.log', new Date().toISOString() + ' - ' + severity + " - " + entry + '\n');
		logstream.write(logEntry);
	}
};

// ======================================================================
// Very inefficient way to "sleep"
// ======================================================================
function sleep(time) {
	if(time < minSleep) time = minSleep;
    var stop = new Date().getTime();
    while(new Date().getTime() < stop + time) {
        ;
    }
}

// ======================================================================
// This is our main HttpServer Handler
// ======================================================================
var server = http.createServer(function (req, res) {

	// debugging
	//console.log(`${req.method} ${req.url}`);
	// parse URL
	const parsedUrl = urlModule.parse(req.url);
	// extract URL path
	let pathname = `.${parsedUrl.pathname}`;
	// based on the URL path, extract the file extention. e.g. .js, .doc, ...
	const extName = path.parse(pathname).ext;
	// mimeMaps file extention to MIME types
	const mimeMap = {
	  '.ico': 'image/x-icon',
	  '.html': 'text/html',
	  '.js': 'text/javascript',
	  '.json': 'application/json',
	  '.css': 'text/css',
	  '.png': 'image/png',
	  '.jpg': 'image/jpeg',
	  '.wav': 'audio/wav',
	  '.mp3': 'audio/mpeg',
	  '.svg': 'image/svg+xml',
	  '.pdf': 'application/pdf',
	  '.doc': 'application/msword'
	};

    if (req.method === 'POST') {
        var body = '';

        req.on('data', function(chunk) {
            body += chunk;
        });

        req.on('end', function() {
            if (req.url === '/') {
                log(SEVERITY_DEBUG, 'Received message: ' + body);
            } else if (req.url = '/scheduled') {
                log(SEVERITY_DEBUG, 'Received task ' + req.headers['x-aws-sqsd-taskname'] + ' scheduled at ' + req.headers['x-aws-sqsd-scheduled-at']);
            }

            res.writeHead(200, 'OK', {'Content-Type': 'text/plain'});
            res.end();
        });
    } else if (req.url.startsWith("/api")) {
		var url = require('url').parse(req.url, true);
		var closeResponse = true;

        // sleep a bit :-)
		var sleeptime = parseInt(url.query["sleep"]);
		if(sleeptime === 0) sleeptime = minSleep;
		log(SEVERITY_DEBUG, "Sleeptime: " + sleeptime);
		sleep(sleeptime);

		// figure out which API call they want to execute
        var status = "Unkown API Call";
		if(url.pathname === "/api/sleeptime") {
			// Usage: /api/sleeptime?min=1234 
			var sleepValue = parseInt(url.query["min"]);
			if(sleepValue >= 0 && sleepValue <= 10000) minSleep = sleepValue;
			status = "Minimum Sleep Time set to " + minSleep;
		}
		if(url.pathname === "/api/echo") {
			// Usage: /api/echo?text=your text to be echoed!
			status = "Thanks for saying: " + url.query["text"];
		}
		if(url.pathname === "/api/login") {
			// Usage: /api/login?username=your user name 
			status = "Welcome " + url.query["username"];
		}
		if(url.pathname === "/api/invoke") {
			// count the invokes for failed requests
			var returnStatusCode = 200;
			if(failInvokeRequestPercentage > 0) {
				invokeRequestCount++;
				var failRequest = (invokeRequestCount % failInvokeRequestPercentage);
				if(failRequest == 0) {
					returnStatusCode = 500;
					invokeRequestCount = 0;
				}
			}

			// Usage: /api/invoke?url=http://www.yourdomain.com 
			var urlRequest = url.query["url"];
			status = "Trying to invoke remote call to: " + urlRequest;
			
			var http = null;
			if(urlRequest.startsWith("https")) http = require("https");
			else http = require("http");
			closeResponse = false;
			var options = {
              	host: urlRequest,
              	path: '/'
            };
			var result = http.get(urlRequest, function(getResponse) {
				log(SEVERITY_DEBUG, 'STATUS: ' + getResponse.statusCode);
				log(SEVERITY_DEBUG, 'HEADERS: ' + JSON.stringify(getResponse.headers));

				// Buffer the body entirely for processing as a whole.
				var bodyChunks = [];
				getResponse.on('data', function(chunk) {
					bodyChunks.push(chunk);
				}).on('end', function() {
					var body = Buffer.concat(bodyChunks);
				  	log(SEVERITY_DEBUG, 'BODY: ' + body);
				  	status = "Request to '" + url.query["url"] + "' returned with HTTP Status: " + getResponse.statusCode + " and response body length: " + body.length;
				  	res.writeHead(returnStatusCode, returnStatusCode == 200 ? 'OK' : 'ERROR', {'Content-Type': 'text/plain'});	
				  	res.write(status);
				  	res.end();
				}).on('error', function(error) {
				  	status = "Request to '" + url.query["url"] + "' returned in an error: " + error;
				  	res.writeHead(returnStatusCode, returnStatusCode == 200 ? 'OK' : 'ERROR', {'Content-Type': 'text/plain'});	
				  	res.write(status);
				  	res.end();					
				  	log(SEVERITY_INFO, status);
				})
			});
		}
		// usage: /api/problem
		// simply returns the problem number as defined in PROBLEM_NUMBER env-variable which is specified
		// Usage: /api/problem?newProblemNumber=1
		// to fake out the problem number
		if(url.pathname === "/api/problem") {
			if (url.query["newProblemNumber"] && url.query["newProblemNumber"] != null) {
				var newProblemNumber = url.query["newProblemNumber"];
				log(SEVERITY_WARNING, "Somebody is changing! problemNumber from " + problemNumber + " to " + newProblemNumber);

				init(newProblemNumber);
			}
			status = "Running problem number: " + problemNumber;
		}

		// usage: /api/causeerror
		if(url.pathname === "/api/causeerror") {
			log(SEVERITY_ERROR, "somebody called /api/causeerror");
			status = "We just caused an error log entry"
		}

		// only close response handler if we are done with work!
		if(closeResponse) {
		   res.writeHead(200, 'OK', {'Content-Type': 'text/plain'});	
		   res.write(status);
		   res.end();
		}
	}
	else if (typeof mimeMap[extName] !== 'undefined')
	{
		// read file from file system
		fs.readFile(pathname, function(err, data){
			if(err){
				res.statusCode = 500;
				res.end(`Error getting the file: ${err}.`);
			} else {
				// if the file is found, set Content-type and send data
				res.setHeader('Content-type', mimeMap[extName] || 'text/plain' );
				res.end(data);
			}
		})
	}
	else
	{
		res.writeHead(200, 'OK', {'Content-Type': 'text/html'});

		// replace problemNumber and background color
		var finalHtml = html.replace("BACKGROUND-COLOR", getBackgroundColor()).replace("PROBLEM_NUMBER", problemNumber).replace("ENVIRONMENT_NAME", environmentName);
        res.write(finalHtml);
        res.end();
	}
	
	requestCount++;
	if(requestCount >= 100) {
		log(SEVERITY_INFO, "Just served another 100 requests!");
		requestCount = 0;
	}
});

// first we initialize!
init(null);

// Listen on port 80, IP defaults to 127.0.0.1
server.listen(port);

// Put a friendly message on the terminal
console.log('Server running at http://127.0.0.1:' + port + '/');
log(SEVERITY_INFO, "Service is up and running - feed me with data!");