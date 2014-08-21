echo "Linting code..."
find lib/ -name '*.coffee' | xargs coffee-jshint --globals atom,module,require,setTimeout,clearTimeout,setInterval,clearInterval,window
echo "Linting tests..."
find spec/ -name '*.coffee' | xargs coffee-jshint --globals atom,module,require,setTimeout,clearTimeout,setInterval,clearInterval,window,describe,it,expect,beforeEach,afterEach,waitsForPromise,waitsFor,runs,spyOn,jasmine
