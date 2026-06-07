from flask import Flask, request
from flask_sse import sse
app = Flask(__name__)
app.config["REDIS_URL"] = "redis://localhost"
app.register_blueprint(sse, url_prefix="/stream")
clients = {}

# 需要Flask框架、安装flask-sse库、Redis数据库、以及waitress
# Windows端运行命令：waitress-serve --host 127.0.0.1 --port 5000 multiplayer_test_server:app

@app.route("/")
def hello():
    return "Hello World"

# 刚进入时使用，直接获取房间内所有人的信息
@app.route("/room")
def room():
    return ""

# 移动时发送到服务器以响应
@app.route("/room/move", methods=["POST"])
def room_move():
    print("someone takes move " + request.json.get("move", "-1"))
    sse.publish({"message": request.json.get("move", "-1")}, type="move")
    return ""

# 开始一局游戏
@app.route("/room/game")
def game_start():
    pass

# 发送广播
@app.route("/room/game/move")
def move():
    print("someone takes move " + request.json.get("move", "-1"))
    pass

if __name__ == "__main__":
    app.run()