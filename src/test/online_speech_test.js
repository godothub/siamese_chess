var express = require("express");
var path = require("path");
var fs = require("fs");
var uuid = require("uuid");
var app = express();
var exec = require('child_process').exec;

var options = {
	//链接自己的SSL证书
	key: fs.readFileSync('/privkey.pem'),
	cert: fs.readFileSync('/fullchain.pem')
};

app.use(express.text());

app.get("/tts", async (req, res) => {
	var content = req.query.content ?? "test_content";
	var voice = req.query.voice ?? "default";
	var speed = req.query.speed ?? "100";
	var pitch = req.query.pitch ?? "50";
	var file = "/tmp/" + uuid.v4() + ".wav";
	await exec(`espeak "${content}" -v ${voice} -s ${speed} -p ${pitch} -w ${file}`, (err, stdout, stderr) => {
		if (err)
		{
			res.send("runtime error");
			return;
		}
		console.log(`${voice} ${content} ${speed} ${pitch}`);
		res.header("Content-Type", "audio/wav")
		   .sendFile(file, (err) => {
				exec(`rm ${file}`);
		   });
	});
});

app.get("/voice_list", async (req, res) => {
	var lang = req.query["lang"]
	await exec(`espeak --voices=${lang}`, (err, stdout, stderr) => {
		if (err)
		{
			res.send("runtime error");
			return;
		}
		res.send(stdout);
	});
});

app.post("/asr", async (req, res) => {
	var content = req.body;
	console.log(content);
	if (!content)
	{
		res.send("no content");
		return;
	}
	var buffer = Buffer.from(content, "base64")
	var file = "/tmp/" + uuid.v4() + ".wav";
	console.log("received wav");
	fs.writeFile(file, buffer, { encoding: null }, async (err) => {
		if (err)
		{
			res.send("runtime error");
			return;
		}
		await exec(`vosk-transcriber --input ${file} --output ${file}.txt && cat ${file}.txt`, (err, stdout, stderr) => {
			if (err)
			{
				res.send("runtime error");
				return;
			}
			console.log(`${stdout}`);
			res.send(stdout);
			exec(`rm ${file} ${file}.txt`);
		});
	});

})

https.createServer(options, app).listen(5000, function() {});