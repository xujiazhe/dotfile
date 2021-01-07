import os
import sys


if len(sys.argv) != 2:
	print("lua file path missing")
	exit(-1)

path=sys.argv[1]

ls = open(path).readlines()
for l in ls:
	if 'PointerTooltipFix' in l:
		print("lua fixed already!")
		exit(-2)


os.system('cp {} {}.bak'.format(path,path))
ls.insert(7, 'local mouse   = require("hs.mouse")\n')

s="""
	elseif thisAlertStyle.atScreenEdge == 3 then
	   local pos = mouse.getAbsolutePosition()
	   -- PointerTooltipFix
	   drawingFrame.x = pos.x
	   drawingFrame.y = pos.y
	   if drawingFrame.x + drawingFrame.w > screenFrame.x+screenFrame.w then
	       drawingFrame.x = screenFrame.x+screenFrame.w - drawingFrame.w
	   end
	   if drawingFrame.y + drawingFrame.h > screenFrame.y+screenFrame.h then
	       drawingFrame.y = screenFrame.y+screenFrame.h - drawingFrame.h
	   end
"""

for i,l in enumerate(ls):
	if l.endswith('thisAlertStyle.atScreenEdge == 2 then\n'):
		ls.insert(i+2,s)
		break

open(path, 'w').writelines(ls)


