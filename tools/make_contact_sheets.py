#!/usr/bin/env python3
"""Assemble actual rendered screenshots; requires Pillow, no network."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
CAP=ROOT/'docs/captures/lot2'
FONT=ROOT/'assets/ui/DejaVuSans.ttf'
def sheet(names,columns,width,title,filename):
 tile_height=width*9//16
 rows=(len(names)+columns-1)//columns
 page=Image.new('RGB',(columns*width,90+rows*(tile_height+36)), '#132e3b')
 draw=ImageDraw.Draw(page)
 draw.text((25,22),title,font=ImageFont.truetype(str(FONT),30),fill='#b4e76a')
 for index,name in enumerate(names):
  picture=Image.open(CAP/(name+'.png')).convert('RGB')
  picture.thumbnail((width-12,tile_height))
  x=(index%columns)*width+(width-picture.width)//2
  y=90+(index//columns)*(tile_height+36)
  page.paste(picture,(x,y))
  draw.text(((index%columns)*width+12,y+tile_height+5),name.replace('_',' '),font=ImageFont.truetype(str(FONT),19),fill='#f5f1e8')
 page.save(ROOT/filename,quality=90,subsampling=0,optimize=True)
sheet(['park_'+str(i) for i in range(1,8)],3,640,'GRINDLISH / 7 parcs / Godot 4.3 - OpenGL réel','APERCU_PARCS.jpg')
sheet(['menu','modes','levels','briefing','help','options','controls','pause','end','shop','shop3d','notebook','quiz','teacher','credits','menu_en','options_en','touch_2400x1080','touch_2560x1600','touch_1280x720'],4,480,'GRINDLISH / interfaces et formats / captures réelles','APERCU_MENUS.jpg')
