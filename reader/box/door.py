#! /usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import division
import os
import sys
import re

# Assumes SolidPython is in site-packages or elsewhwere in sys.path
from solid import *
from solid.utils import *

SEGMENTS = 16

case_h = 42
case_d = 18
case_w = 65
case_th = 1.5
coil_sup_l = 3
coil_sup_d = 3
# Inner diameter of coil
coil_sup_w = 43
coil_sup_h = 31
# Width of screw block
sw = 12

def coil_sup():
    return cylinder(coil_sup_d/2, coil_sup_l)

def coil_sups():
    s1 = translate([-(coil_sup_w-coil_sup_d)/2, -(coil_sup_h-coil_sup_d)/2, 0])(coil_sup())
    s2 = translate([(coil_sup_w-coil_sup_d)/2, -(coil_sup_h-coil_sup_d)/2, 0])(coil_sup())
    s3 = translate([(coil_sup_w-coil_sup_d)/2, (coil_sup_h-coil_sup_d)/2, 0])(coil_sup())
    s4 = translate([-(coil_sup_w-coil_sup_d)/2, (coil_sup_h-coil_sup_d*2)/2, 0])(coil_sup())
    return s1+s2+s3+s4

def bottom():
    return translate([-case_w/2, -case_h/2, 0])(cube([case_w, case_h, case_th]))

def frame():
    outer = translate([-case_w/2, -case_h/2, case_th])(cube([case_w, case_h, case_d]))
    iw = case_w-2*case_th
    ih = case_h-2*case_th
    inner = translate([-iw/2, -ih/2, case_th])(cube([iw, ih, case_d+1]))
    return outer-inner

def led_support():
    return cylinder(h=4, d=5)

def led_hole():
    return down(1)(cylinder(h=10, d=2.5))

def screw_block():
    block = translate([-sw/2, -case_h/2, 0])(cube([sw, case_h, case_d+case_th]))
    hole = cylinder(h=case_h+2, r=1.5) + down(0.1)(cylinder(h=4, r1=3, r2=1.5))
    return block - hole

def assembly():
    bt = bottom()
    cs = up(case_th)(forward(0)(coil_sups()))
    fr = frame()
    led_dist = 20
    l1 = left(led_dist/2)(led_support())
    lh1 = left(led_dist/2)(led_hole())
    l2 = right(led_dist/2)(led_support())
    lh2 = right(led_dist/2)(led_hole())
    s1 = left(case_w/2+sw/2-0.1)(screw_block())
    s2 = right(case_w/2+sw/2-0.1)(screw_block())
    return cs+fr+bt+l1+l2+s1+s2-lh1-lh2

if __name__ == '__main__':
    a = assembly()
    scad_render_to_file(a, file_header='$fn = %s;' % SEGMENTS, include_orig_code=False)
