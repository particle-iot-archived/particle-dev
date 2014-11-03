echo "Linting code..."
find lib/ -name '*.coffee' | xargs coffee-jshint --globals atom,module,require,setTimeout,clearTimeout,setInterval,clearInterval,window,localStorage,__dirname,process
echo "Linting tests..."
find spec/ -name '*.coffee' | xargs coffee-jshint --globals atom,module,require,setTimeout,clearTimeout,setInterval,clearInterval,window,localStorage,__dirname,process,describe,it,expect,beforeEach,afterEach,waitsForPromise,waitsFor,runs,spyOn,jasmine
