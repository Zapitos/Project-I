#!/usr/bin/env python3
"""Atualiza a seção de colaboradores no README.

Regras:
- Lê nomes de contribuidores via `git shortlog -sne`.
- Aplica overrides opcionais de papel/foco em `tools/contributors_overrides.json`.
- Substitui conteúdo entre marcadores <!-- CONTRIBUTORS-LIST:START --> e <!-- CONTRIBUTORS-LIST:END -->.

Uso:
    python tools/update_contributors.py

Dependências: apenas git instalado e Python 3.8+.
"""
from __future__ import annotations
import json
import re
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
README = REPO_ROOT / "README.md"
OVERRIDES_FILE = REPO_ROOT / "tools" / "contributors_overrides.json"
START = "<!-- CONTRIBUTORS-LIST:START -->"
END = "<!-- CONTRIBUTORS-LIST:END -->"

def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True, cwd=REPO_ROOT).strip()

def get_contributors() -> list[dict]:
    output = run(["git", "shortlog", "-sne", "HEAD"])
    contributors = []
    for line in output.splitlines():
        # Ex: '  25\tNome <email>' ou '  3\tOutro Nome <email>'
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue
        commits_str, rest = parts
        commits = int(commits_str)
        # Extrai nome (antes do email)
        name = re.sub(r"<.*?>", "", rest).strip()
        contributors.append({
            "name": name,
            "commits": commits,
        })
    return contributors


def load_overrides() -> dict:
    if OVERRIDES_FILE.exists():
        try:
            return json.loads(OVERRIDES_FILE.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def build_table(contributors: list[dict], overrides: dict) -> str:
    rows = ["| Nome / Handle | Função / Foco | Commits |", "|---------------|---------------|---------|"]
    for c in contributors:
        name = c["name"]
        commits = c["commits"]
        override = overrides.get(name, {})
        role = override.get("role", "-")
        rows.append(f"| {name} | {role} | {commits} |")
    return "\n".join(rows)


def replace_section(readme_text: str, new_table: str) -> str:
    pattern = re.compile(rf"{re.escape(START)}(.*?){re.escape(END)}", re.DOTALL)
    replacement = f"{START}\n{new_table}\n{END}"
    if pattern.search(readme_text):
        return pattern.sub(replacement, readme_text)
    # Se não existe, anexar ao final
    return readme_text.rstrip() + f"\n\n{replacement}\n"


def main():
    contributors = get_contributors()
    overrides = load_overrides()
    table = build_table(contributors, overrides)
    text = README.read_text(encoding="utf-8")
    updated = replace_section(text, table)
    if updated != text:
        README.write_text(updated, encoding="utf-8")
        print("README atualizado com lista de contribuidores.")
    else:
        print("Nenhuma mudança na lista de contribuidores.")

if __name__ == "__main__":
    main()
