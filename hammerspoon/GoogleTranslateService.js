// npm install --save @vitalets/google-translate-api
const http = require('http');
const process = require('process');
const SocksProxyAgent = require('socks-proxy-agent');

var proxy = process.env.socks_proxy || 'socks://127.0.0.1:1080';
agent = new SocksProxyAgent(proxy);  //node 中的全局代理

// 在模块中 增加代理
// vim ~/node_modules/@vitalets/google-translate-token/index.js +84
const translate = require('@vitalets/google-translate-api');

//create a server object:
http.createServer(function (req, res) {
	if (!(req.url === '/gg' && req.method === 'POST')) {
		res.end();
		return;
	}
	collectRequestData(req, result => {
		// console.log(result);
		translate(result.data, {to: result.to || 'zh-CN'}, typeof agent === 'undefined' ? {} : {agent: agent}).then(tres => {
			console.log(tres.text);
			// console.log(tres.from.language.iso);
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
}).listen(8520, '127.0.0.1');

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
