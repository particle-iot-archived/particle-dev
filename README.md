[![Build Status](https://magnum.travis-ci.com/spark/spark-ide.svg?token=M4rP8W5QPGszZyem6TGE&branch=master)](https://magnum.travis-ci.com/spark/spark-ide)

# Installing

```
git clone git@github.com:spark/spark-ide.git
apm link ./spark-ide
cd spark-ide
mkdir node_modules
cd node_modules
git clone https://github.com/voodootikigod/node-serialport.git serialport
cd serialport
npm install
node_modules/node-pre-gyp/bin/node-pre-gyp build --target=0.11.13
cd ../..
apm update
```
