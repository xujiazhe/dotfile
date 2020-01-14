const pinyin4js = require('pinyin4js');

const zn2en = { //部分来自这里 https://github.com/martnst/localize-mainmenu/blob/master/languages/zh-CN.json
	"前置全部窗口": "Bring All to Front",
	"首字母大写": "Capitalize",
	"立即检查文稿": "Check Document Now",
	"检查拼写和语法": "Check Grammar With Spelling",
	"键入时检查拼写": "Check Spelling While Typing",
	"关闭": "Close",
	"拷贝": "Copy",
	"自动纠正拼写": "Correct Spelling Automatically",
	"剪切": "Cut",
	"删除": "Delete",
	"文件": "File",
	"编辑": "Edit",
	"视图": "View",
	"显示": "View", //加了这一个
	"查找": "Find",
	"查找下一个": "Find Next",
	"查找上一个": "Find Previous",
	"查找与替换\u2026": "Find and Replace\u2026", //TODO 这个可能是...
	"查找\u2026": "Find\u2026",
	"帮助": "Help",
	"隐藏其他": "Hide Others",
	"跳到所选内容": "Jump to Selection",
	"变为小写": "Make Lower Case",
	"变为大写": "Make Upper Case",
	"最小化": "Minimize",
	"打开\u2026": "Open\u2026",
	"粘贴": "Paste",
	"粘贴并匹配样式": "Paste and Match Style",
	"偏好设置\u2026": "Preferences\u2026",
	"重做": "Redo",
	"全选": "Select All",
	"服务": "Services",
	"全部显示": "Show All",
	"显示拼写和语法": "Show Spelling and Grammar",
	"显示替换": "Show Substitutions",
	"智能拷贝\/粘贴": "Smart Copy\/Paste",
	"智能破折号": "Smart Dashes",
	"智能链接": "Smart Links",
	"智能引号": "Smart Quotes",
	"语音": "Speech",
	"拼写": "Spelling",
	"拼写和语法": "Spelling and Grammar",
	"开始朗读": "Start Speaking",
	"停止朗读": "Stop Speaking",
	"替换": "Substitutions",
	"文本替换": "Text Replacement",
	"转换": "Transformations",
	"撤销": "Undo",
	"查找所选内容": "Use Selection for Find",
	"替换所选内容": "Use Selection for Replace",
	"窗口": "Window",
	"缩放": "Zoom",
	// null : "Bring <AppName> Window to Front",
	"关于 <AppName>": "About <AppName>",
	"退出 <AppName>": "Quit <AppName>",
	"隐藏 <AppName>": "Hide <AppName>",
};

// more detail methods in test
// WITH_TONE_NUMBER--数字代表声调，WITHOUT_TONE--不带声调，WITH_TONE_MARK--带声调

// output: xià#mén#nǐ#hǎo#dà#shà#xià#mén
// console.log(pinyin4js.convertToPinyinString('哎', '#', pinyin4js.WITHOUT_TONE))

//首字母风格
// output: xmnhdsxm
// console.log(pinyin4js.convertToPinyinString('厦门你好大厦厦门', '', pinyin4js.FIRST_LETTER))
// https://github.com/sp-study-group/Shuang/blob/master/js/schemes/wzrrudpn.js
const teuu = {
	a: 'oa'
	, ai: 'ol'
	, an: 'oj'
	, ang: 'oh'
	, ao: 'ok'
	, e: 'oe'
	, ei: 'oz'
	, en: 'of'
	, eng: 'og'
	, er: 'or'
	, o: 'oo'
	, ou: 'ob'
};
const first = {
	ch: 'i'
	, sh: 'u'
	, zh: 'v'
};
function udpn(c){
	//return pinyin4js.convertToPinyinString(menuItem.AXTitle, '', pinyin4js.FIRST_LETTER)[0]
	const pinyin = pinyin4js.convertToPinyinString(c[0], '', pinyin4js.WITHOUT_TONE);
	return teuu[pinyin] && teuu[pinyin][0] || (
		pinyin[1] === 'h' ? first[pinyin.slice(0,2)] : pinyin[0]
	)
}
// console.log(udpn('哎'));

function keyIndexMenus(menus, level) {
	const fullKeyList = 'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ`';
	let keyIndexes = {};
	for (let key of fullKeyList) {
		keyIndexes[key] = null;
	}
	for (let i = 0; i < menus.length; i++) {
		const menuItem = menus[i] = {
			AXTitle: menus[i],
			tapKey: null
		};
		if (level === 0 && (i in [0, 1])) {
			menuItem.tapKey = "`1"[i];
			keyIndexes[menuItem.tapKey] = i + 1;
		} //应用名字区别开来
		else{
			//如何取菜单首字母
			//     中文? 有英文对应的菜单:拼音首字母
			//     英文? 首字母
			let tapkey = (
				menuItem.AXTitle.charCodeAt(0) > 127 ?
					(zn2en[menuItem.AXTitle] ?
						zn2en[menuItem.AXTitle][0]
						: udpn(menuItem.AXTitle))[0]
					: menuItem.AXTitle[0]
			);
			tapkey = tapkey.toLowerCase();
			//首字母 在本级菜单中可用
			menuItem.tapKey = keyIndexes[tapkey] === null ? tapkey : null;
		}

		if (menuItem.tapKey !== null) {
			if (menuItem.tapKey === menuItem.AXTitle[0]) {
				menuItem.firstChar = menuItem.tapKey;
				menuItem.title = menuItem.AXTitle.slice(1);
			} else {
				menuItem.title = menuItem.AXTitle;
			}
			keyIndexes[menuItem.tapKey] = i + 1;
		} else {
			menuItem.title = menuItem.AXTitle;
		}
	}

	let keyList = [];
	for (let i = 0, j = -1; i < menus.length; i++) {
		if (!menus[i].tapKey) {
			while (keyIndexes[fullKeyList[++j]]) ;
			menus[i].tapKey = fullKeyList[j];
			keyIndexes[menus[i].tapKey] = i + 1;
		}
		keyList.push(menus[i].tapKey);
	}
	// console.log(menus);
	return {
		keyIndexes: keyIndexes,
		keyList: keyList
	};
}

// var data = ["Apple", "New","Open..."]
// var res = keyIndexMenus(data, 0);
// console.log(res);
module.exports = keyIndexMenus;
