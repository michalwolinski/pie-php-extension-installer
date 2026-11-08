# Prints the directory where PIE keeps pie.json and pie.lock for the PHP it runs on.
pie show -v 2>/dev/null | sed -n 's/^Using pie.json: //p' | head -1 | xargs dirname
