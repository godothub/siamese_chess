var express = require("express")
var https = require("https")
var fs = require("fs")
var uuid = require("uuid")
var cookie_parser = require("cookie-parser")
var express_sse = require("express-sse")
var sse = new express_sse([])

var app = express()

var options = {
	//链接自己的SSL证书
	key: fs.readFileSync('/privkey.pem'),
	cert: fs.readFileSync('/fullchain.pem')
}

app.use(express.json())
app.use(cookie_parser())

var users = {}

function check_user_id(req, res)
{
	if (!req.cookies || !req.cookies.client_id)
	{
		var client_id = uuid.v4()
		res.cookie("client_id", client_id)
		console.log(`new user ${client_id}`)
		users[client_id] = {time: Date.now(), by: "a8"}
		sse.send({message: client_id}, "new_guest")
		return client_id
	}
	return req.cookies.client_id
}

app.get("/stream", sse.init)

app.get("/room", function(req, res)
{
	var client_id = check_user_id(req, res)
	res.send({current_position: users[client_id].by, users: users})
})

app.post("/room/move", function(req, res)
{
	var client_id = check_user_id(req, res)
	users[client_id] = {time: Date.now(), by: req.body.move}
	console.log(`${client_id} is moved to ${req.body.move}`)
	sse.send({message: {user:client_id, move:req.body.move}}, "move")
	res.send("")
})

setInterval(() => {
	users = {}
}, 3600000)

https.createServer(options, app).listen(5001, function() {})
