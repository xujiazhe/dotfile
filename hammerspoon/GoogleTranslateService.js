// npm install --save @vitalets/google-translate-api
const http = require('http');
const translate = require('@vitalets/google-translate-api');
const process = require('process');


// translate('I spea Dutch!', {from: 'en', to: 'nl'}).then(res => {
//     console.log(res);
//     console.log(res.text);
//     //=> Ik spea Nederlands!
//     console.log(res.from.text.autoCorrected);
//     //=> false
//     console.log(res.from.text.value);
//     //=> I [speak] Dutch!
//     console.log(res.from.text.didYouMean);
//     //=> true
// }).catch(err => {
//     console.error(err);
// });            node ./test2.js


//create a server object:
http.createServer(function (req, res) {
    if (req.url === '/gg' && req.method === 'POST') {
        collectRequestData(req, result => {
            // console.log(result);

            translate(result.data, {to: result.to || 'zh-CN'}).then(tres => {
                // console.log(tres);
                console.log(tres.text);
                //=> I speak English
                // console.log(tres.from.language.iso);
                //=> nl
                res.writeHead(200, {'Content-Type': 'application/json'});
                res.write(JSON.stringify(tres));
                res.end();

            }).catch(err => {
                console.error(err);
                res.writeHead(502);
                res.end();
            });
            // res.end(`Parsed data belonging to ${result.fname}`);
        });
    }
    else res.end();
}).listen(8520, '127.0.0.1'); //the server object listens on port 8080


function collectRequestData(request, callback) {
    const FORM_URLENCODED = "application/json";
    if (request.headers['content-type'] === FORM_URLENCODED) {
        let body = [];
        request.on('data', chunk => {
            body.push(chunk)
        });
        request.on('end', () => {
            body = JSON.parse(body);
            console.log("转json成功");
            callback(body);
        });
    } else {
        callback(null);
    }
}


console.log(process.pid);

// process.on('SIGTERM', function(code) {
//     // do *NOT* do this
//     setTimeout(function() {
//         console.log('This will not run');
//     }, 0);
//     console.log('About to exit with code:', code);
// });
