#sudo apt install inotify-tools -y

export PROJECT="project"
while inotifywait -r -e modify,create,delete "$PWD/src/"; do
    sleep 2
    echo "Reconfiguring CMake and building the project..."
    /usr/bin/cmake -DCMAKE_BUILD_TYPE=Debug -G Ninja -S "$PWD" -B "$PWD/cmake-build-debug"
    cd cmake-build-debug && ninja | tee build_log.txt && cd ..
    sleep 5
done