var http = require("http");
var fs = require("fs")

http.createServer(function (request, response) {

    fs.readFile('patch.lua', function (err, data) {
        if (err) {
            return console.error(err);
        }
        response.end(data);
    });
    // Send the response body as "Hello World"

}).listen(8088);

console.log('patch you can download on port 8088');
