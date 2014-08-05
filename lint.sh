echo "Linting code..."
coffee-jshint --globals atom,module,require,console lib/*.coffee
echo "Linting tests..."
coffee-jshint --globals require,atom,describe,it,expect,beforeEach,afterEach,waitsForPromise,waitsFor,runs,spyOn,console spec/*.coffee
