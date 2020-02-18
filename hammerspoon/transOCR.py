#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import base64
import functools
import hashlib
import json
import sys
import urllib

import requests
import urllib.parse
import urllib.request

printe = functools.partial(print, file=sys.stderr)

# os.chdir("/Users/xujiazhe/.hammerspoon")

service_url = "http://deepi.sogou.com/api/sogouService"


def Post(url, params):
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    req = urllib.request.Request(url, urllib.parse.urlencode(params).encode(encoding='utf-8'), headers)
    response = urllib.request.urlopen(req)
    return response.read()


def translateOCR(url, params):
    r = urllib.request.urlopen(url, urllib.parse.urlencode(params).encode(encoding='utf-8'))
    return r.read()


def Post3(url, params):
    r = requests.post(url, params)
    return r.text


def File2base64(file):
    f = open(file, 'rb')
    return base64.b64encode(f.read()).decode()


def CalSign(pid, service, salt, sign_image, key):
    m = hashlib.md5()
    data = "%s%s%s%s%s" % (pid, service, salt, sign_image, key)
    # printe(data)
    m.update(data.encode(encoding='utf-8'))
    return m.hexdigest()

# from PIL import ImageGrab
# im = ImageGrab.grabclipboard()
# im.save('somefile.png','PNG')

if __name__ == '__main__':
    img_file = 'en.png'
    img_file = '/Users/xujiazhe/text.png'
    img_file = sys.argv[1]

    pid = 'ffe4e3d268668e62c3c5fc7a5cd04528'
    key = '8d66f66dfd5b0da5e80df89cd7e7eb91'
    # service = 'basicOpenOcr'
    service = 'translateOpenOcr'
    salt = '1508404016012'
    # lang = 'zh-CHS'
    fromLang = 'en'
    toLang = 'zh-CHS'
    # lang = 'en'
    img_base64 = File2base64(img_file)
    # printe(img_base64[0:1024])
    sign = CalSign(pid, service, salt, img_base64[0:1024], key)
    # printe(sign)

    param_data = {
        "pid": pid,
        "service": service,
        # "lang":lang,
        'from': fromLang,
        'to': toLang,
        "salt": salt,
        "image": img_base64,
        "sign": sign
    }

    # printe param_data
    jsonResult = translateOCR(service_url, param_data)
    resultDict = json.loads(jsonResult.decode('utf-8'))

    try:
        del resultDict['pic']
        result = resultDict.get('result')
        if result is None:
            printe("没找到结果")
        else:
            zhResult = ''.join(r['content'] for r in result)
            enResult = ''.join(r['trans_content'] for r in result)

            print(zhResult)
            print(enResult)

    except Exception as e:
        print("Error ", e, resultDict)

# brew install python3;  pip3 install requests;
# 创建项目venv
# 安装requests
