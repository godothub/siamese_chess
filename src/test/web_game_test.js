var express = require("express");
var cookieParser = require("cookie-parser");
var fs = require("fs");
var path = require("path");
var https = require("https");
var compression = require('compression');

var options = {
	//链接自己的SSL证书
	key: fs.readFileSync('/privkey.pem'),
	cert: fs.readFileSync('/fullchain.pem')
}

var app = express();

function compression_filter(req, res)
{
	
	const large_file = ["/game/index.js", "/game/index.pck", "/game/index.side.wasm", "/game/libsiamese.web.template_release.wasm32.wasm"]
	if (req.path in large_file)
	{
		return true;
	}
	return false;
}

app.use(compression({ filter: compression_filter }));

app.get(/game.*/, function(req, res)
{
	res
		.header("Cross-Origin-Opener-Policy", "same-origin")
		.header("Cross-Origin-Embedder-Policy", "require-corp")
		.header("X-Powered-By", "-")
		.sendFile(path.join(__dirname, req.path));
});

app.get("/", function(req, res)
{
	res.redirect("/game/index.html");
});

https.createServer(options, app).listen(443, function() {});
