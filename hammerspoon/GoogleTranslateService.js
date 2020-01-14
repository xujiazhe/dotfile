// npm install --save @vitalets/google-translate-api  pinyin4js
const http = require('http');

const process = require('process');
const SocksProxyAgent = require('socks-proxy-agent');
const keyMenu = require('./keyMenu');

var proxy = process.env.socks_proxy || 'socks://127.0.0.1:1080';
agent = new SocksProxyAgent(proxy);  //node 中的全局代理
const PORT = process.env.PORT || 8521;

// 在模块中 增加代理
// TODO vim node_modules/@vitalets/google-translate-token/index.js +84    添加全局代理
//     , typeof agent === 'undefined'? {}: {agent: agent}
const translate = require('@vitalets/google-translate-api');

http.createServer(function (req, res) {
	//菜单Key索引
	if (req.url === '/pinyin' && req.method === 'POST') {
		collectRequestData(req,payload => {
			res.writeHead(200, {'Content-Type': 'application/json'});
			var keyData = keyMenu(payload.data, Number(!payload.first_level));
			res.write(JSON.stringify(keyData));
			res.end();
		});
		return;
	}

	//翻译功能
	if (req.url === '/gg' && req.method === 'POST') {
		collectRequestData(req, payload => {
			// console.log(payload);
			translate(payload.data, {to: payload.to || 'zh-CN'}, typeof agent === 'undefined' ? {} : {agent: agent}).then(tres => {
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
			// res.end(`Parsed data belonging to ${payload.fname}`);
		});
		return ;
	}
}).listen(PORT, '127.0.0.1');

function collectRequestData(request, callback) {
	if (request.headers['content-type'] === "application/json") {
		let body = [];
		request.on('data', chunk => {
			body.push(chunk)
		});
		request.on('end', () => {
			body = JSON.parse(body);
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
