var express = require("express");
var uuid = require("uuid");
var cookie_parser = require("cookie-parser")
var express_sse = require("express-sse");
var sse = new express_sse([]);

var app = express();
app.use(express.json());
app.use(cookie_parser());

var users = {}

function check_user_id(req, res)
{
	if (!req.cookies || !req.cookies.client_id)
	{
		var client_id = uuid.v4();
		res.cookie("client_id", client_id);
		console.log(`new user ${client_id}`);
		users[client_id] = 0
		sse.send({message: client_id}, "new_guest");
		return client_id;
	}
	return req.cookies.client_id;
}

app.get("/stream", sse.init);

app.get("/room", function(req, res)
{
	var client_id = check_user_id(req, res);
	res.send({current_position: users[client_id], users: users})
});

app.post("/room/move", function(req, res)
{
	var client_id = check_user_id(req, res);
	console.log(`${client_id} is moved to ${req.body.move}`)
	sse.send({message: {user:client_id ,move:req.body.move}}, "move")
	res.send("")
});

app.get("/room/game", function(req, res)
{
	check_user_id(req, res);
	res.send("")
});


app.get("/room/game/move", function(req, res)
{
	check_user_id(req, res);
	console.log(req.body)
	res.send("")
});


var server = app.listen(5000, function() {});
