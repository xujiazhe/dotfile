# -*- coding: utf-8 -*-
#
# Created by xujiazhe on 2019-03-26.
#
import re
import sys


def groupSamePreSpace(prefixLens):
    for i, l in enumerate(prefixLens):
        if i:
            if l != prefixLens[i - 1]:
                return False
    return True


# 连续几行(非空) 分组  每组
#    开头相同长度的空格缩进 (除掉第一行) 换成一个空格
#    连接成一行 结尾是- 去掉 空格和-


# print(lines, file=open("data_read", "w"))
def join(lines):
    ls = [[]]
    for l in lines:
        if l.strip():
            ls[-1].append(l)
        else:
            ls.append([])

    ls = list(filter(lambda x: len(x), ls))
    prefixSpacePattern = re.compile('^([ ]?)')
    sSymbols = chr(0x2010) + ' '  # '- '
    # fp = open("data_write", "a+")

    for i, group in enumerate(ls):
        prefixLens = [len(prefixSpacePattern.match(l).group(1)) for l in group]
        if not any(len(l) > 100 for l in group):
            res = "\n".join(group)
            print(res, '\n')
            continue

        replaceCnt = 0
        if groupSamePreSpace(prefixLens[1:]):
            group = ls[i] = list(l.lstrip(" ") for l in group)
            for j, l in enumerate(group):
                # print(ord(l[-1]))
                if l[-1] == sSymbols[0]:
                    replaceCnt += 1

        res = " ".join(group)
        if replaceCnt:
            res = res.replace(sSymbols, '', replaceCnt)

        print(res, '\n')
        # print(res, file=fp)
    # fp.close()


if __name__ != "__main__":  # TODO 是否被脚本调用?
    lines = """
    lines2   The ps utility displays a header line, followed by lines containing information about all of your processes that have controlling terminals.

     A different set of processes can be selected for display by using any combination of the -a, -G, -g, -p, -T, -t, -U, and -u options.  If more than one of
     these options are given, then ps will select all processes which are matched by at least one of the given options.

     For the processes which have been selected for display, ps will usually display one line per process.  The -M option may result in multiple output lines (one
     line per thread) for some processes.  By default all of these output lines are sorted first by controlling terminal, then by process ID.  The -m, -r, and -v
     options will change the sort order.  If more than one sorting option was given, then the selected processes will be sorted by the last sorting option which
     was specified.

     For the processes which have been selected for display, the information to display is selected based on a set of keywords (see the -L, -O, and -o options).
     The default output format includes, for each process, the process' ID, controlling terminal, CPU time (including both user and system time), state, and asso‐
     ciated command. """

    lines = """     -g n       Use graphics chars for tree.  n = 1: IBM-850, n = 2: VT100, n = 3: UTF8.

     -l n       Show a maximum of n levels.

     -p pid     Show only parents and descendants of the process pid.

     -s string  Show only parents and descendants of processes containing the string in their commandline.

     -U         Do not show branches containing only root processes.

     -u user    Show only parents and descendants of processes of user.

     -w         Wide output, not truncated to terminal width.
"""

    lines = lines.split('\n')
    join(lines)
else:
    lines = sys.stdin.read()
    lines = lines.split('\n')
    join(lines)
