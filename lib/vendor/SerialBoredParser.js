module.exports = {


	MakeParser: function (boredDelay) {
		let boredTimer,
			chunks = [];

		let whenBored = function (emitter) {
			emitter.emit('data', chunks.join(''));
			chunks = [];
		};

		let updateTimer = function (emitter) {
			clearTimeout(boredTimer);
			boredTimer = setTimeout(function () {
				whenBored(emitter);
			}, boredDelay);
		};


		return function (emitter, buffer) {
			chunks.push(buffer.toString());
			updateTimer(emitter);
		};
	}


};
