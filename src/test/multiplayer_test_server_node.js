var express = require("express");
var SSE = require("express-sse");
var sse = new SSE([]);

var app = express();
app.use(express.json());
var stream = ""

app.get("/stream", sse.init);

app.get("/", function(req, res) {
	res.send("Hello world")
});

app.get("/room", function(req, res) {
	res.send("")
});

app.post("/room/move", function(req, res) {
	console.log("someone moved to " + req.body.move)
	sse.send({message: req.body.move}, "move")
	res.send("")
});

app.get("/room/game", function(req, res) {
	res.send("")
});


app.get("/room/game/move", function(req, res) {
	console.log(req.body)
	res.send("")
});


var server = app.listen(5000, function() {});
