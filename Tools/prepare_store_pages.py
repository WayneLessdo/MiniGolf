"""从政策及支持正文生成中英文静态页面，不引入第三方脚本。"""
from pathlib import Path
import html
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "release/web"
STYLE = """html{color-scheme:light dark}body{font:17px/1.75 system-ui,-apple-system,sans-serif;max-width:720px;margin:0 auto;padding:32px 24px 64px;background:Canvas;color:CanvasText}nav{display:flex;gap:24px;flex-wrap:wrap;margin-bottom:32px}a{color:LinkText;text-underline-offset:4px}h1{font-size:30px;line-height:1.25}h2{font-size:21px;margin-top:32px}p{overflow-wrap:anywhere}footer{margin-top:48px;border-top:1px solid GrayText;padding-top:16px}a:focus-visible{outline:3px solid Highlight;outline-offset:4px}@media(max-width:420px){body{padding:24px 18px}}"""


def render(source: str, language: str, page: str) -> str:
    blocks = source.strip().split("\n\n")
    heading = blocks.pop(0).splitlines()
    body = "<h1>" + html.escape(heading[0]) + "</h1>"
    body += "".join("<p>" + html.escape(line) + "</p>" for line in heading[1:])
    for block in blocks:
        lines = block.splitlines()
        if len(lines) > 1:
            body += "<h2>" + html.escape(lines[0]) + "</h2>"
            body += "<p>" + html.escape("\n".join(lines[1:])) + "</p>"
        else:
            body += "<p>" + html.escape(block) + "</p>"
    english = language == "en"
    suffix = "" if english else "-zh-Hans"
    support, privacy, contact = ("Support", "Privacy", "Email Wayne") if english else ("用户支持", "隐私政策", "联系 Wayne")
    switch = f'{page}-zh-Hans.html' if english else f'{page}.html'
    return (
        '<!doctype html>\n<html lang="' + language + '"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        "<title>" + html.escape(heading[0]) + "</title><style>" + STYLE + "</style>"
        '</head><body><nav aria-label="' + ("Help pages" if english else "帮助页面") + '">'
        f'<a href="support{suffix}.html">{support}</a><a href="privacy{suffix}.html">{privacy}</a>'
        f'<a href="mailto:waynelessdo@gmail.com">{contact}</a>'
        f'<a href="{switch}" lang="' + ("zh-Hans" if english else "en") + '">' + ("简体中文" if english else "English") + '</a></nav>'
        "<main>" + body + "</main><footer>MiniGolf: Putt &amp; Bloom · Wayne · "
        '<a href="mailto:waynelessdo@gmail.com">waynelessdo@gmail.com</a></footer></body></html>\n'
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    policy = (ROOT / "Resources/PrivacyPolicy.txt").read_text(encoding="utf-8")
    (OUT / "privacy.txt").write_text(policy, encoding="utf-8")
    for name in ["privacy", "support"]:
        for language, source_suffix, page_suffix in [("en", "-en", ""), ("zh-Hans", "", "-zh-Hans")]:
            source = (OUT / (name + source_suffix + ".txt")).read_text(encoding="utf-8")
            (OUT / (name + page_suffix + ".html")).write_text(render(source, language, name), encoding="utf-8")
    (OUT / "index.html").write_text((OUT / "support.html").read_text(encoding="utf-8"), encoding="utf-8")
    metadata = ROOT / "release/app-store"
    (metadata / "copyright.txt").write_text("2026 Wayne\n", encoding="utf-8")
    hosting_path = OUT / "hosting.json"
    hosting = json.loads(hosting_path.read_text(encoding="utf-8")) if hosting_path.exists() else {}
    contact_path = metadata / "contact.json"
    # 重新生成网页时保留已核实的审核联系资料及说明，避免清空已有填写结果。
    contact = json.loads(contact_path.read_text(encoding="utf-8")) if contact_path.exists() else {}
    contact.update({
        "public_name": "Wayne", "support_email": "waynelessdo@gmail.com",
        "privacy_policy_url": hosting.get("privacy_policy_url"), "support_url": hosting.get("support_url"),
    })
    for key in ["review_contact_first_name", "review_contact_last_name", "review_contact_phone"]:
        contact.setdefault(key, None)
    contact.setdefault("note", "公开名称由用户提供；审核姓名与电话须使用真实联系资料。网址以hosting.json的实际部署记录为准。")
    contact_path.write_text(json.dumps(contact, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Generated privacy/support pages and public contact metadata.")


if __name__ == "__main__":
    main()
