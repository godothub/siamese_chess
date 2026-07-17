var express = require("express")
var path = require("path");
var uuid = require("uuid");
var app = express();
var exec = require('child_process').exec;

app.get("/tts", async (req, res) => {
    
	var content = req.query.content ?? "test_content";
	var voice = req.query.voice ?? "default";
	var speed = req.query.speed ?? "100";
	var pitch = req.query.pitch ?? "50";
	var file = uuid.v4();
	await exec(`espeak "${content}" -v ${voice} -s ${speed} -p ${pitch} -w /tmp/${file}.wav`, (err, stdout, stderr) => {
		if (err)
		{
			res.send("runtime error");
            return;
		}
        console.log(`${voice} ${content} ${speed} ${pitch}`);
		res.header("Content-Type", "audio/wav")
           .sendFile(`/tmp/${file}.wav`, (err) => {
                exec(`rm /tmp/${file}.wav`);
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

app.listen(5000, function() {});