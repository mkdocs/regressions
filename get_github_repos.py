import os
import subprocess
import sys
import yaml
from pathlib import Path

TOKEN = os.environ.get("GITHUB_TOKEN")

exclude = {
    "MaartenGr/BERTopic",  # torch
    "MaartenGr/KeyBERT",  # torch
    "phurwicz/hover",  # torch
    "voidful/TFkit",  # torch
    "art049/odmantic",  # no mkdocs.yml
    "mackelab/sbi",  # no mkdocs.yml
    "dssg/triage",  # no mkdocs.yml
    "sherpaai/Sherpa.ai-Federated-Learning-Framework",  # no mkdocs.yml
    "mne-tools/mne-study-template",  # no mkdocs.yml
    "drivendataorg/nbautoexport",  # no mkdocs.yml
    "jayqi/spongebob",  # no mkdocs.yml
    "pawamoy/cookie-poetry",  # no mkdocs.yml
    "albumentations-team/albumentations.ai",  # no mkdocs.yml
    "brown-bnc/xnat-tools",  # no mkdocs.yml
    "nicolasfauchereau/DL4SEAS",  # no mkdocs.yml
    "Mohamed-Kaizen/fastapi-template",  # no mkdocs.yml
    "vascoferreira25/new-python-project-guide",  # no mkdocs.yml
    "rdeville/My_Dotfiles.Myrepos_Template",  # no mkdocs.yml
    "mplesser/azcam-webserver",  # no mkdocs.yml
    "mplesser/azcam-arc",  # no mkdocs.yml
    "mplesser/azcam",  # no mkdocs.yml
    "Mohamed-Kaizen/python-template",  # no mkdocs.yml
    "LuizGuzzo/TCC-rastreamento",  # no mkdocs.yml
    "Lifeng3624/data",  # no mkdocs.yml
    "kuwv/spades",  # no mkdocs.yml
    "kuwv/python-cookiecutter",  # no mkdocs.yml
    "krishansubudhi/flaskWebApp",  # no mkdocs.yml
    "jnvilo/scriptslib",  # no mkdocs.yml
    "daxartio/package-template",  # no mkdocs.yml
    "dadyarri/bjorn",  # no mkdocs.yml
    "cgupm/ratp_poll",  # no mkdocs.yml
    "cgupm/crtm_poll",  # no mkdocs.yml
    "AI2Business/ai2business",  # no mkdocs.yml
    "abhiTronix/vidgear",  # can't build current, missing extra deps
}


def get_repos():
    from github import Github

    github = Github(TOKEN)
    search = github.search_code("mkdocstrings+filename:mkdocs.yml")
    return [
        result.repository.full_name
        for result in sorted(search, key=lambda result: result.repository.stargazers_count, reverse=True)
        if result.repository.full_name not in exclude
    ]


if __name__ == "__main__":
    print("\n".join(get_repos()))
