# -*- coding: utf-8 -*-
from pathlib import Path

root = Path(__file__).resolve().parents[1]
pages = [
    ('Tee off', 'default; resting ball, grass reveal 0.6s and flag growth 0.4s'),
    ('Main menu', 'default; quiet course preview, start and continue areas'),
    ('Level selection', 'default; rounded course previews and earned-star status'),
    ('Compact gameplay', 'default; an unobstructed ball, hole and idle pull ring'),
    ('Separated controls', 'aiming; a minimap, short direction arrow and one pull ring'),
    ('Handheld mode', 'default; manual upper-course and lower-controls equivalent'),
    ('Pull to putt', 'charging; one continuous drag, ring arc for power, direction arrow'),
    ('Hole result', 'success; a sparse 0.8s gold particle celebration and earned stars'),
    ('Penalty reset', 'penalty; a 0.3s red edge, safe-position reset and free retry'),
    ('Free cosmetics', 'default; ball and flag preview, no prices or stat upgrades'),
    ('Settings', 'default; sound, haptics, manual layout and tee-off replay'),
    ('Night course concept', 'default; a quiet decorative night course, no daily timer'),
    ('Local score concept', 'default; compact local turn-based scorecards, no account')
]
poses = [
    ('compact', 'Portrait compact single-column course, bottom thumb-zone pull ring overlay and collapsible minimap. Respect top, bottom, left and right safe areas independently. No physical hinge on the outer display.'),
    ('regular', 'Landscape regular layout: left minimap, pull ring and stars; right unobstructed course. Align the canal obstacle with the supplied division mask. No controls on the crease; avoid camera masks and respect all four safe areas independently.'),
    ('folded', 'Folded L or book-like concept with upper course and lower controls as a manual equivalent. The crease is only a canal obstacle and transition. Keep buttons outside division and camera masks and respect four independent safe areas. No angle-driven layout rule.')
]
palette = 'Use FPColors.mint #9BD4B8 grass, FPColors.cream #FBF7F0 sand, FPColors.gold #E8B96A rewards, FPColors.penalty #E06B5C warnings and FPColors.water #6FB4D6 canal. Friendly Physics, rounded forms, soft grass texture and restrained glass panels.'
end = ' One UI concept at least 1024 pixels on the short edge. No text, logos, ads, payment, joystick, multiple sliders or separate PUTT button. Do not print token names. For Reduce Motion use static grass, flag and results without particles or shake. This is concept art, not a simulator screenshot.'
lines = ['# AI image prompts', '', 'Built-in image generation is unavailable in this session. No API/CLI image generation was used. This is the requested prompt-only fallback. Save future concept images in Resources/AIConcepts, and pure decorative backgrounds in Resources/Backgrounds. Concept pages do not imply implemented app features.', '', '| Screen / state | Pose | Prompt |', '|---|---|---|']
for title, detail in pages:
    for pose, layout in poses:
        lines.append(f'| {title} / {detail.split(";")[0]} | {pose} | Generate a UI image: {detail}. {layout} {palette}{end} |')
for state, detail in [('default','idle ball and clear hole'),('aiming','short direction arrow and engaged ring'),('charging','pulled-back ring and a visible power arc'),('success','ball entering the cup with sparse gold particles, 0.8s keyframe'),('penalty','ball reset to safe ground, restrained red border, 0.3s keyframe')]:
    for pose, layout in poses:
        lines.append(f'| Gameplay / {state} | {pose} | Generate a UI image: mini-golf in the {state} state, {detail}. {layout} {palette}{end} |')
lines += ['', '## Pure decorative background', '', 'Generate a UI image: Seamless top-down short grass for mini-golf, FPColors.mint #9BD4B8 and FPColors.mintDeep #5FB98F only, diffuse lighting, no ball, flag, hole, path, text, button, UI or dominant object. All edges and the center remain equally quiet for independent safe-area layouts. Opaque 2048 by 2048 pixels. Use only as a decorative background, never as an interaction mask.', '']
target = root / 'docs/ai-image-prompts.md'
with target.open('x', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('Saved 54 UI prompts plus one background prompt.')
