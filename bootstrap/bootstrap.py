#!/usr/bin/env python3


import os
import re
import sys


# helpers
def flatten(xss): return [x for xs in xss for x in xs]
def get_conts(file_path):
    conts = []
    with open(file_path, 'r') as f: conts = f.read().split('\n')
    return (file_path, conts)


# program
def main():
    overwrite = False
    if '-y' in sys.argv[1:]: overwrite = True
    inp_fls = list(set(filter(os.path.isfile, sys.argv[1:])))
    fl_conts = list(map(get_conts, inp_fls))
    tangle_blks = flatten(list(map(lambda fl: get_blks('tangle', fl), fl_conts)))
    for blk in list(map(expand_refs, tangle_blks)):
        if os.path.isfile(blk[0]):
            if overwrite == False:
                question = input(blk[0] + ' already exists, overwrite? [Y/n] ')
                if question in ['n', 'N', 'no', 'No', 'NO']:
                    continue
            os.remove(blk[0])
        os.makedirs(os.path.dirname(blk[0]) or './', exist_ok = True)
        with open(blk[0], 'w+') as f:
            for ln in blk[2]: f.write(ln + '\n')


def get_blks(blk_type, fl_conts):
    blks = []

    lnm = 0
    while len(fl_conts[1][lnm:]) > 3:
        if re.match(r'(^\`.+\`:$)|(^(\`.+\` \| )?\[.+\]\(.+\):$)', fl_conts[1][lnm]) and re.match(r'^```+.*$', fl_conts[1][lnm + 1]):
            if blk_type == 'tangle' and not re.match(r'(\`.+\` \| )?\[.+\]\(.+\):$', fl_conts[1][lnm]):
                lnm += 1
                continue

            out_or_nm = None
            if blk_type == 'tangle':
                out_or_nm = os.path.join(os.path.dirname(fl_conts[0]), re.findall(r'(?<=\]\().+(?=\):$)', fl_conts[1][lnm])[0])
            elif blk_type == 'named':
                if fl_conts[1][lnm][0] == '`': out_or_nm = re.findall(r'(?<=^\`).+(?=\`)', fl_conts[1][lnm])[0]
                elif fl_conts[1][lnm][0] == '[': out_or_nm = re.findall(r'(?<=^\[).+(?=\]\()', fl_conts[1][lnm])[0]
            close_lnm = fl_conts[1][lnm + 2:].index(re.findall('^```+', fl_conts[1][lnm + 1])[0]) + lnm + 2
            blk_conts = fl_conts[1][lnm + 2:close_lnm]

            blks.append((out_or_nm, fl_conts[0], blk_conts))
        lnm += 1

    return blks


def expand_refs(blk):
    new_conts = []

    for ln in blk[2]:
        if re.match(r'^.*<<<.+>>>.*$', ln):
            ref = re.findall(r'(?<=<<<).+(?=>>>)', ln)[0].split(':')
            (ref_file, ref_name) = ('', '')
            match ref:
                case [fl, nm]: (ref_file, ref_name) = (os.path.join(os.path.dirname(blk[1]), fl), nm)
                case [_]: (ref_file, ref_name) = (blk[1], ref[0])

            if os.path.isfile(ref_file) and True in map(lambda blk: blk[0] == ref_name, get_blks('named', get_conts(ref_file))):
                (prefix, suffix) = (re.findall(r'^.*(?=<<<)', ln)[0], re.findall(r'(?<=>>>).*$', ln)[0])
                pot_blks = get_blks('named', get_conts(ref_file))
                ref_conts = []
                for pot_blk in pot_blks:
                    if pot_blk[0] == ref_name: ref_conts = expand_refs(pot_blk)[2]

                for ref_ln in ref_conts:
                    if ref_ln == '':
                        new_conts.append('')
                        continue
                    new_conts.append(prefix + ref_ln + suffix)

                continue

        new_conts.append(ln)

    return (blk[0], blk[1], new_conts)


# main
if __name__ == '__main__':
    main()
