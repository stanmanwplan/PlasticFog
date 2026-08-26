#!/usr/bin/env bash
# Republish the docs: private repo HEAD -> public repo -> GitHub Pages.
set -e
MSG="${1:?usage: ./publish.sh \"commit message for the public repo\"}"
cd ~/pf_doc
[ -z "$(git status --porcelain)" ] || { echo "ABORT: uncommitted changes in ~/pf_doc — commit first (publish snapshots HEAD)."; exit 1; }
[ -d ~/pf_public/.git ] || { echo "ABORT: ~/pf_public missing — re-stage per the flip sequence."; exit 1; }
git archive HEAD | tar -x -C ~/pf_public
rm -rf ~/pf_public/_campaign
cd ~/pf_public
git add -A
git commit -m "$MSG" || echo "(no changes to publish)"
git push
source ~/pf_doc/.venv/bin/activate
mkdocs gh-deploy --force
