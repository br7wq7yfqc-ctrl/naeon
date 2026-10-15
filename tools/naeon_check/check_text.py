#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_text.py — проверка прозы NAEON по навыку naeon-literary v3.

Только стандартная библиотека. Ничего не правит, только показывает места.

Использование:
    python3 check_text.py text/*.md
    python3 check_text.py text/TOM_I_SET_05_08.md --markdown > report.md
    python3 check_text.py file.md --category borrow,calque --width 300

Категории (ключи для --category):
    borrow    заимствования и жаргон (по словоформам)
    calque    кальки и канцелярит (раздел «Слово, образ, концовка» и стоп-список навыка)
    mech      механически образованные формы и явно нерусские слова
    contrast  «не X, а Y» и «а не X» (оценивает человек)
    chop      разрубленная формула «Не X. Это Y.»

Пропускаются строки разметки: заголовки #, ---, **Плата…**, **Полоса…**,
**Секвенция…**, строки с картинками ![](). Скрипт только помечает
кандидатов; решение «дефект или ложное срабатывание» принимает человек.
Для каждого места показаны пометки контекста: [реплика] — место внутри
прямой речи (строка начинается с тире), [кавычки] — внутри «…».
"""
import argparse
import re
import sys
from collections import OrderedDict

CYR = "А-Яа-яЁё"
LB = r"(?<![%s])" % CYR
LA = r"(?![%s])" % CYR


def word(pattern):
    """Целое слово: слева и справа не кириллическая буква."""
    return re.compile(LB + "(?:" + pattern + ")" + LA, re.I)


# ---------------------------------------------------------------- 1. заимствования
M = r"(?:а|у|ом|е|ы|и|ов|ам|ами|ах)?"          # окончания мужского рода и пустое
BORROW = OrderedDict([
    ("апдейт", word(r"апдейт%s|апдейти(?:ть|л[аио]?|м|т|ли)" % M)),
    ("баг", word(r"баг%s" % M)),
    ("бандл", word(r"бандл%s" % M)),
    ("батч", word(r"батч(?:а|у|ем|е|и|ей|ам|ами|ах)?")),
    ("гейт", word(r"гейт%s" % M)),
    ("дефолт", word(r"дефолт[а-яё]*")),
    ("дока", word(r"дока|доки|доке|доку|докой|доков")),
    ("деплой", word(r"деплой[а-яё]*|деплои(?:ть|л[а-яё]*|м|т|ли)|деплою")),
    ("кастомный", word(r"кастом[а-яё]*|кастомиз[а-яё]*")),
    ("кейс", word(r"кейс%s" % M)),
    ("конфиг", word(r"конфиг%s" % M)),
    ("лог", word(r"лог%s" % M)),
    ("маппинг", word(r"маппинг[а-яё]*")),
    ("нативный", word(r"нативн[а-яё]*")),
    ("онбординг", word(r"онбординг[а-яё]*")),
    ("пайплайн", word(r"пайплайн[а-яё]*")),
    ("ретрай", word(r"ретра(?:й|ев|я|ю|ем|и|ях|ям|ями)[а-яё]*")),
    ("релиз", word(r"релиз[а-яё]*")),
    ("снапшот", word(r"снапшот[а-яё]*")),
    ("фича", word(r"фич(?:а|и|е|у|ей|ам|ами|ах)?")),
    ("функционал", word(r"функционал%s" % M)),
    ("шарить", word(r"шар(?:ить|ю|ишь|ит|им|ите|ят|ил|ила|ило|или|ь|ьте|я)")),
    ("корректный (как оценка)", word(r"корректн[а-яё]*")),
    ("валидный (как оценка)", word(r"валидн[а-яё]*|валидаци[а-яё]*|валидир[а-яё]*")),
])

# ---------------------------------------------------------------- 2. кальки и канцелярит
CALQUE = OrderedDict([
    ("стоит отметить", word(r"стоит\s+отметить")),
    ("важно понимать", word(r"важно\s+понимать")),
    ("в контексте", word(r"в\s+контексте")),
    ("на самом деле", word(r"на\s+самом\s+деле")),
    ("играть роль", word(r"игра[а-яё]*\s+(?:[а-яё]+\s+){0,2}рол[ьи]ю?")),
    ("сделать смысл", word(r"(?:с)?дела[а-яё]*\s+(?:[а-яё]+\s+)?смысл[а-яё]*")),
    ("является", word(r"являе[тш]ся|являются|являл[а-яё]*|являясь|являться|являющ[а-яё]+|являюсь|являемся|является")),
    ("представляет собой", word(r"представля[а-яё]*\s+собой")),
    ("осуществлять", word(r"осуществ[а-яё]+")),
    ("данный", word(r"данн(?:ый|ая|ое|ые|ого|ому|ым|ом|ой|ою|ую|ых|ыми)")),
    ("в рамках", word(r"в\s+рамках")),
    ("с целью", word(r"с\s+целью")),
    ("в связи с", word(r"в\s+связи\s+с")),
    ("имеет место", word(r"име[а-яё]+\s+место")),
])

# ---------------------------------------------------------------- 3. механические формы
PREF = r"(?:за|на|по|при|до|вы|пере|от|об|под|раз|с|у)?"
VEND = r"(?:ю|ишь|ит|им|ите|ят|ил|ила|ило|или|ить|ится|ятся|илось|илась|ились|ился)"
MECH = OrderedDict([
    ("убедюсь", word(r"убедю(?:сь)?")),
    ("победю", word(r"победю")),
    ("авторить", word(r"(?:за|на|по|при|до|вы|пере|от|об|под|раз|с|у|)автор%s" % VEND)),
    ("мастерится / замастерю",
     word(r"мастер(?:ится|ятся|илось|илась|ились|ился)|(?:за|при|до|пере)мастер(?:ю|ишь|ит|им|ите|ят|ил[а-яё]*|ить)")),
])
LATIN_OK = {"NAEON", "NAE", "NAEXOS", "Prime", "NAEXOS Prime"}
RE_LATIN_TOKEN = re.compile(r"[A-Za-z][A-Za-z0-9_-]*")
# слово, где внутри одного слова (без дефиса) перемешаны латиница и кириллица
RE_MIXED = re.compile(r"(?<![A-Za-zА-Яа-яЁё-])(?=[A-Za-z]*[А-Яа-яЁё])(?=[А-Яа-яЁё]*[A-Za-z])[A-Za-zА-Яа-яЁё]+(?![A-Za-zА-Яа-яЁё-])")
# гибрид через дефис: JSON-файл, файл-JSON, API-токен
RE_HYBRID = re.compile(r"[A-Za-z0-9]+-[А-Яа-яЁё]+|[А-Яа-яЁё]+-[A-Za-z0-9]+")

# ---------------------------------------------------------------- 4. «не X, а Y», «а не X»
RE_NE_A = re.compile(
    LB + r"не\s+[^,.!?;:—]{1,70}?,\s*(?:—\s*[^—.!?]{1,60}?[,.]?\s*—\s*)?а\s+"
    r"(?!не\s|то\s|там\s|потом\s|теперь\s|затем\s|после\s)", re.I)
RE_A_NE = re.compile(r"[,—]\s*а\s+не\s+[а-яё]", re.I)
RE_NE_ONLY = re.compile(r"(?:^|[.!?]\s+)(?:—\s*)?не\s+(?:просто|только)", re.I)

# ---------------------------------------------------------------- 5. «Не X. Это Y.»
RE_CHOP = re.compile(
    r"(?:(?:^|[.!?…]\s+)(?:—\s*)?Не\s+[^.!?]{1,100}[.]\s+(?:—\s*)?Это\s)"
    r"|(?:Это\s+не\s+[^.!?]{1,100}[.]\s+(?:—\s*)?Это\s)")

CATS = OrderedDict([
    ("borrow", "Заимствования и жаргон"),
    ("calque", "Кальки и канцелярит"),
    ("mech", "Механические формы и явно нерусские слова"),
    ("contrast", "«не X, а Y» и «а не X»"),
    ("chop", "Разрубленная формула «Не X. Это Y.»"),
])

SKIP_PREFIXES = ("#", "![", "**Плата", "**Полоса", "**Секвенция")


def is_markup(line):
    s = line.strip()
    return (not s) or s == "---" or s.startswith(SKIP_PREFIXES)


def sentence_bounds(text, pos):
    """Границы предложения, содержащего позицию pos."""
    start = 0
    for m in re.finditer(r"[.!?…][»\"]?\s+", text[:pos]):
        start = m.end()
    m = re.search(r"[.!?…][»\"]?(?:\s|$)", text[pos:])
    end = pos + m.end() if m else len(text)
    return start, end


def speech_flags(line, pos):
    """Пометки контекста для места pos в строке."""
    flags = []
    s = line.lstrip()
    if s.startswith("—"):
        # реплика: сегменты между « — » чередуются: речь / авторская ремарка
        offs = [m.start() for m in re.finditer(r"\s—\s", line)]
        idx = sum(1 for o in offs if o < pos)
        # первая тире стоит в начале строки и в offs не попадает
        flags.append("реплика" if idx % 2 == 0 else "ремарка в реплике")
    opened = line.count("«", 0, pos) - line.count("»", 0, pos)
    if opened > 0:
        flags.append("кавычки")
    return flags


def add(res, cat, fn, ln, line, m, label, extra=None):
    s, e = sentence_bounds(line, m.start())
    sent = line[s:e].strip()
    flags = speech_flags(line, m.start())
    if extra:
        flags.append(extra)
    res.append(dict(cat=cat, file=fn, line=ln, label=label,
                    found=m.group(0).strip(), sent=sent, flags=flags,
                    chapter=None))


def scan_file(path):
    res = []
    chapter = ""
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    for i, line in enumerate(lines, 1):
        if line.startswith("#"):
            chapter = line.lstrip("# ").strip()
        if is_markup(line):
            continue
        n0 = len(res)
        for label, rx in BORROW.items():
            for m in rx.finditer(line):
                add(res, "borrow", path, i, line, m, label)
        for label, rx in CALQUE.items():
            for m in rx.finditer(line):
                extra = None
                if label == "на самом деле":
                    before = line[:m.start()].rstrip()
                    after = line[m.end():].lstrip()
                    if after.startswith(",") or not before or before[-1] in ".!?—,":
                        extra = "связка"
                add(res, "calque", path, i, line, m, label, extra)
        for label, rx in MECH.items():
            for m in rx.finditer(line):
                add(res, "mech", path, i, line, m, label)
        for m in RE_MIXED.finditer(line):
            add(res, "mech", path, i, line, m, "смешанный алфавит в слове")
        for m in RE_HYBRID.finditer(line):
            add(res, "mech", path, i, line, m, "гибрид с латиницей через дефис")
        for m in RE_LATIN_TOKEN.finditer(line):
            tok = m.group(0)
            if tok in LATIN_OK or tok.upper() in LATIN_OK:
                continue
            # часть смешанного слова уже учтена выше
            a, b = m.start(), m.end()
            if (a > 0 and re.match("[%s]" % CYR, line[a - 1])) or \
               (b < len(line) and re.match("[%s]" % CYR, line[b])):
                continue
            add(res, "mech", path, i, line, m, "латиница в прозе")
        for m in RE_NE_A.finditer(line):
            add(res, "contrast", path, i, line, m, "не X, а Y")
        for m in RE_A_NE.finditer(line):
            add(res, "contrast", path, i, line, m, "а не X")
        for m in RE_NE_ONLY.finditer(line):
            add(res, "contrast", path, i, line, m, "не просто/не только")
        for m in RE_CHOP.finditer(line):
            add(res, "chop", path, i, line, m, "Не X. Это Y.")
        for r in res[n0:]:
            r["chapter"] = chapter
    # убрать дубли (одно и то же место, найденное двумя шаблонами)
    seen, out = set(), []
    for r in res:
        key = (r["cat"], r["file"], r["line"], r["label"], r["found"], r["sent"][:60])
        if key in seen:
            continue
        seen.add(key)
        out.append(r)
    return out


def trunc(s, width):
    s = re.sub(r"\s+", " ", s)
    return s if len(s) <= width else s[: width - 1] + "…"


def render_text(results, width, cats, files):
    out = []
    totals = OrderedDict()
    for key in cats:
        rs = [r for r in results if r["cat"] == key]
        totals[key] = len(rs)
        out.append("== %s: %d" % (CATS[key], len(rs)))
        last = None
        for r in rs:
            fl = (" [" + ", ".join(r["flags"]) + "]") if r["flags"] else ""
            out.append("%s:%d%s  <%s> %s" % (r["file"], r["line"], fl, r["label"],
                                            trunc(r["sent"], width)))
        out.append("")
    out.append("ИТОГО: " + "; ".join("%s — %d" % (CATS[k], v) for k, v in totals.items()))
    out.append("Файлов проверено: %d" % len(files))
    return "\n".join(out)


def render_md(results, width, cats, files):
    out = ["# Отчёт check_text.py", ""]
    out.append("Файлов проверено: %d" % len(files))
    out.append("")
    out.append("| Категория | Найдено |")
    out.append("|---|---:|")
    for key in cats:
        out.append("| %s | %d |" % (CATS[key], sum(1 for r in results if r["cat"] == key)))
    out.append("")
    for key in cats:
        rs = [r for r in results if r["cat"] == key]
        out.append("## %s (%d)" % (CATS[key], len(rs)))
        out.append("")
        for r in rs:
            fl = (" [" + ", ".join(r["flags"]) + "]") if r["flags"] else ""
            out.append("- `%s:%d`%s <%s> %s" % (r["file"], r["line"], fl, r["label"],
                                               trunc(r["sent"], width)))
        out.append("")
    return "\n".join(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Проверка прозы NAEON по навыку naeon-literary v3")
    ap.add_argument("files", nargs="+", help="md-файлы")
    ap.add_argument("--category", default=",".join(CATS),
                    help="через запятую: " + ", ".join(CATS))
    ap.add_argument("--width", type=int, default=400, help="макс. длина показанного предложения")
    ap.add_argument("--markdown", action="store_true", help="вывод в Markdown")
    ap.add_argument("--json", action="store_true", help="вывод в JSON (для постобработки)")
    args = ap.parse_args(argv)
    cats = [c.strip() for c in args.category.split(",") if c.strip()]
    for c in cats:
        if c not in CATS:
            ap.error("неизвестная категория: " + c)
    results = []
    for p in args.files:
        results.extend(scan_file(p))
    results = [r for r in results if r["cat"] in cats]
    if args.json:
        import json
        print(json.dumps(results, ensure_ascii=False, indent=1))
    elif args.markdown:
        print(render_md(results, args.width, cats, args.files))
    else:
        print(render_text(results, args.width, cats, args.files))
    return 0


if __name__ == "__main__":
    sys.exit(main())
