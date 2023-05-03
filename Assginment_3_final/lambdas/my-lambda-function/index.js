const movies = [
	"Hello World!"
];
exports.handler = async (event) => {
	return {
		statusCode: 200,
		headers: {
			"Content-Type": "application/json",
		},
		body: JSON.stringify({ movies }),
	};
};