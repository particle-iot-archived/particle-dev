echo "Linting code..."
find lib/ -name '*.coffee' | xargs coffee-jshint --globals atom,module,require
echo "Linting tests..."
find spec/ -name '*.coffee' | xargs coffee-jshint --globals require,atom,describe,it,expect,beforeEach,afterEach,waitsForPromise,waitsFor,runs,spyOn
