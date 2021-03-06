#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ${DIR}

rm -rf _book

for d in */; do

  if [ ! -f ${d}/book.json ]; then
    continue
  fi

  echo "Generate PDF for book ${d}"

  gitbook install --log error ${d} >/dev/null
  gitbook pdf --log warn ${d} "${d}$(basename ${d}).pdf"
done

echo "Generate website"

gitbook install --log error
gitbook build --log warn

find _book -name "SUMMARY.md" | xargs rm -f
find _book -name "book.json" | xargs rm -f
cp book.json _book/
