var express = require("express");
var https = require("https");
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
app.use(express.raw({type: "audio/wav"}))

app.post("/tts", async (req, res) => {
	var content = req.body;
	console.log(content);
	if (!content)
	{
		res.send("no content");
		return;
	}
	var voice = req.query.voice ?? "default";
	var speed = req.query.speed ?? "100";
	var pitch = req.query.pitch ?? "50";
	var file = "/tmp/" + uuid.v4() + ".mp3";
	console.log(`${voice} ${content} ${speed} ${pitch}`);
	await exec(`espeak "${content}" -v ${voice} -s ${speed} -p ${pitch} --stdout | ffmpeg -i pipe:0 -q:a 9 -ar 11025 -ac 1 -acodec libmp3lame ${file}`, (err, stdout, stderr) => {
		if (err)
		{
			console.log(stderr);
			res.send("runtime error");
			return;
		}
		res.header("Content-Type", "audio/mp3")
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
			console.log(stderr);
			res.send("runtime error");
			return;
		}
		res.send(stdout);
	});
});

app.post("/asr", async (req, res) => {
	var content = req.body;
	if (!content)
	{
		res.send("no content");
		return;
	}
	console.log(content);
	var file = "/tmp/" + uuid.v4() + ".wav";
	fs.writeFile(file, content, { encoding: null }, async (err) => {
		if (err)
		{
			console.log(stderr);
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