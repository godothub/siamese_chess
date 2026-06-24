emsdk activate
rm -rf bin/windows/*
rm -rf bin/android/*
rm -rf bin/web/*
scons platform=windows target=template_release use_mingw=yes debug_symbols=no optimize=speed_trace
scons platform=android target=template_release debug_symbols=no optimize=speed_trace
scons platform=web target=template_release debug_symbols=no optimize=speed_trace
scons platform=linuxbsd target=template_release use_mingw=yes debug_symbols=no optimize=speed_trace
godot --headless --export-release "Windows Desktop" bin/windows/SiameseChess-SecondPrototype-Windows.zip
godot --headless --export-release Android bin/android/SiameseChess-SecondPrototype-Android.apk
godot --headless --export-release Web bin/web/index.html
godot --headless --export-release Linux bin/linux/SiameseChess-SecondPrototype-Linux.zip
7z a bin/web/SiameseChess-SecondPrototype-Web.zip bin/web/*
butler login
butler push bin/windows/SiameseChess-SecondPrototype-Windows.zip FaMuLan/SiameseChess:windows
butler push bin/android/SiameseChess-SecondPrototype-Android.apk FaMuLan/SiameseChess:android
butler push bin/web/SiameseChess-SecondPrototype-Web.zip FaMuLan/SiameseChess:web