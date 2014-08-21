echo "Generating documentation..."
find lib/ -name '*.coffee' | xargs docco
