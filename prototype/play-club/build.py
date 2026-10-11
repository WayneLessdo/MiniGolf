"""Bundle the original local sources into one dependency-free, offline HTML."""
from pathlib import Path
root = Path(__file__).resolve().parent
html = (root / 'index.html').read_text()
html = html.replace('<link rel="stylesheet" href="style.css">', '<style>' + (root / 'style.css').read_text() + '</style>')
for name in ('data.js', 'engine.js', 'app.js'):
    script = (root / name).read_text().replace('</script', '<\\/script')
    html = html.replace(f'<script src="{name}"></script>', '<script>' + script + '</script>')
output = root / 'FoldPutt-好玩研究所.html'
output.write_text(html)
print(output)
