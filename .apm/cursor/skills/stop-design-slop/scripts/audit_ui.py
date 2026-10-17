#!/usr/bin/env python3
"""Heuristic static audit for common AI/template UI signals.

This script does NOT judge design quality. It finds textual patterns worth reviewing.
Usage: python scripts/audit_ui.py path/to/frontend [--json]
"""
from __future__ import annotations
import argparse, json, re
from pathlib import Path
from collections import Counter

EXTS={'.html','.css','.scss','.sass','.js','.jsx','.ts','.tsx','.vue','.svelte','.mdx'}
PATTERNS={
 'radius': re.compile(r'\brounded(?:-[\w\[\]./%-]+)?\b|border-radius\s*:',re.I),
 'pill': re.compile(r'rounded-full|border-radius\s*:\s*999|\bpill\b|\bchip\b',re.I),
 'gradient': re.compile(r'gradient|bg-gradient|linear-gradient|radial-gradient',re.I),
 'blur_glass': re.compile(r'backdrop-blur|backdrop-filter|glassmorphism|\bglass\b',re.I),
 'glow': re.compile(r'\bglow\b|box-shadow\s*:[^;]*(?:#|rgb|hsl)',re.I),
 'centered': re.compile(r'text-center|justify-center|items-center|text-align\s*:\s*center',re.I),
 'three_col': re.compile(r'grid-cols-3|repeat\(\s*3\s*,\s*1fr\s*\)',re.I),
 'card_word': re.compile(r'\bcard\b',re.I),
 'generic_icon': re.compile(r'\b(Sparkles|Wand|Magic|Rocket|Brain|Zap|Shield|Globe|Bolt)\b',re.I),
 'generic_copy': re.compile(r'unlock the power|seamlessly|supercharge|transform your workflow|everything you need|built for the future|smarter insights|powerful\.\s*simple\.\s*intuitive',re.I),
}

def files(root: Path):
    if root.is_file():
        if root.suffix.lower() in EXTS: yield root
        return
    for p in root.rglob('*'):
        if p.is_file() and p.suffix.lower() in EXTS and not any(x in p.parts for x in ('node_modules','.next','dist','build','.git')):
            yield p

def audit(root: Path):
    totals=Counter(); per_file=[]
    for p in files(root):
        try: txt=p.read_text('utf-8',errors='ignore')
        except OSError: continue
        counts={k:len(rx.findall(txt)) for k,rx in PATTERNS.items()}
        counts={k:v for k,v in counts.items() if v}
        if counts:
            totals.update(counts); per_file.append({'file':str(p),'signals':counts})
    warnings=[]
    if totals['radius']>=12: warnings.append('High radius-token frequency: review for indiscriminate rounding rather than semantic shape roles.')
    if totals['pill']>=5: warnings.append('Frequent pill/capsule signals: verify each represents status, tags, filters, compact selection, or another capsule-like semantic.')
    if totals['gradient']>=4 and (totals['blur_glass'] or totals['glow']): warnings.append('Gradient + blur/glow stacking detected: verify there is a deliberate brand/spatial rationale.')
    if totals['card_word']>=12: warnings.append('Frequent card terminology: inspect for excessive common-region grouping / nested surface proliferation.')
    if totals['centered']>=10: warnings.append('Heavy centering signals: check whether dense or operational content would scan better on a strong leading alignment axis.')
    if totals['three_col']>=2: warnings.append('Repeated three-column grids: verify equal visual weight is justified by equal information importance.')
    if totals['generic_icon']>=3: warnings.append('Repeated generic icon vocabulary: remove icons that do not aid recognition, state, navigation, or action comprehension.')
    if totals['generic_copy']>=1: warnings.append('Generic benefit-language detected: replace with concrete product nouns, actions, and outcomes.')
    return {'path':str(root),'totals':dict(totals),'warnings':warnings,'files':per_file}

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('path',type=Path); ap.add_argument('--json',action='store_true'); args=ap.parse_args()
    result=audit(args.path)
    if args.json: print(json.dumps(result,indent=2)); return
    print('Stop Design Slop — heuristic audit')
    print(f"Scanned: {result['path']}")
    if not result['totals']: print('No configured textual signals found.'); return
    print('\nSignals:')
    for k,v in sorted(result['totals'].items(), key=lambda kv:(-kv[1],kv[0])): print(f'  {k:14} {v}')
    print('\nReview prompts:')
    if result['warnings']:
        for w in result['warnings']: print(f'  - {w}')
    else: print('  - No thresholds crossed; manual review is still required.')
    print('\nThis tool detects implementation patterns, not design quality. Treat every warning as a question, not a failure.')
if __name__=='__main__': main()
