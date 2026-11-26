#!/usr/bin/env python3
"""Verify native A02 evidence and assemble matched comparison views (Pillow)."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
from zipfile import ZipFile
from PIL import Image, ImageChops, ImageDraw, ImageOps

VIEWS = ('front', 'rear', 'side', 'top', 'bottom', 'front-detail', 'rear-iso')


def read_artifact(path):
    with ZipFile(path) as archive:
        members = {}
        for name in archive.namelist():
            key = PurePosixPath(name).name
            if not key or name.endswith('/'):
                continue
            if key in members:
                raise ValueError(f'Duplicate artifact basename: {key}')
            members[key] = name
        workload = json.loads(archive.read(members['a02-v10-workload.json']))
        evidence = json.loads(archive.read(members['a02-v15-evidence.json']))
        rows = workload['states']
        matrix = {(row['faction'], row['lod'], row['damage']): row['resources'] for row in rows}
        if len(rows) != 80 or set(matrix) != {(f,l,d) for f in range(8) for l in (8,13) for d in range(5)}:
            raise ValueError('Incomplete/duplicate resource matrix')
        images = {}
        frames = evidence['frames']
        if not len(frames) == evidence['expected_frames'] == evidence['actual_frames'] or len({f['file'] for f in frames}) != len(frames):
            raise ValueError('Incomplete/duplicate evidence frame index')
        if {f['file'] for f in frames} != {k for k in members if k.endswith('.png')}:
            raise ValueError('Unexpected PNG inventory')
        for frame in frames:
            name = frame['file']
            raw = archive.read(members[name])
            if hashlib.sha256(raw).hexdigest() != frame['sha256']:
                raise ValueError(f'Hash mismatch: {name}')
            with Image.open(io.BytesIO(raw)) as im:
                if im.format != 'PNG' or im.size != (960,680):
                    raise ValueError(f'Unexpected image format: {name}')
                images[name] = im.convert('RGB')
        return workload['revision'], matrix, images


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('baseline', type=Path)
    p.add_argument('candidate', type=Path)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    old, a, left = read_artifact(args.baseline)
    new, b, right = read_artifact(args.candidate)
    out = args.output
    out.mkdir(parents=True, exist_ok=True)
    names = [f'a02-v2-{view}.png' for view in VIEWS]
    names += [f'a02-f{f}-lod13.png' for f in range(8)]
    names += [f'a02-v8-d{d}.png' for d in range(5)]
    report = {'baseline':old,'candidate':new,'verified_frames':[len(left),len(right)],'states':80,
              'battle_geometry_unchanged':all(a[k]['triangles']==b[k]['triangles'] and a[k]['instances']==b[k]['instances'] for k in a if k[1]==8),
              'peak_resources':{str(lod):{metric:max(v[metric] for k,v in b.items() if k[1]==lod) for metric in ('instances','triangles','unique_meshes','unique_materials')} for lod in (8,13)},
              'pixel_comparison':[], 'art_approval':'PENDING HUMAN REVIEW; pixel difference is not an aesthetic score'}
    macro = sorted(k for k in right if '-macro-' in k)
    report['candidate_macro_frames'] = macro
    report['artifact_sha256'] = {role:hashlib.sha256(path.read_bytes()).hexdigest() for role,path in [('baseline',args.baseline),('candidate',args.candidate)]}
    canvas = Image.new('RGB',(1000,48+len(names)*360),'#202932')
    draw = ImageDraw.Draw(canvas)
    draw.text((12,12),f'{old} baseline | {new} candidate | native Godot evidence',fill='white')
    for i,name in enumerate(names):
        l,r=left[name],right[name]
        changed=ImageChops.difference(l,r).convert('L').point(lambda x:255 if x>6 else 0).histogram()[255]
        report['pixel_comparison'].append({'file':name,'changed_pixel_fraction':round(changed/(l.width*l.height),6)})
        y=48+i*360
        draw.text((12,y),name,fill='white')
        for x,im in [(12,l),(506,r)]:
            canvas.paste(ImageOps.contain(im,(482,332)),(x,y+20))
    canvas.save(out/'comparison.png')
    if macro:
        sheet = Image.new('RGB',(980,28+len(macro)*704),'#202932')
        labels = ImageDraw.Draw(sheet)
        labels.text((10,8),f'{new} | Candidate-only closeups, not matched comparisons',fill='white')
        for i,name in enumerate(macro):
            y=28+i*704
            labels.text((10,y),name,fill='white')
            sheet.paste(right[name],(10,y+20))
        sheet.save(out/'macro.png')
    (out/'review.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='pixel_comparison'},indent=2))


if __name__ == '__main__':
    main()
