#!/bin/bash
# READ-ONLY recon for SEO p3 (2026-11-15). Writes redacted reports into the IP-locked ops folder. Changes no site file.
H=/home/u450178537; D=$H/domains; K=$1
OPS=$D/digitalenvisioned.net/public_html/.ops-20261114; mkdir -p "$OPS"
printf 'Require ip 52.26.208.45\n' > "$OPS/.htaccess"
red(){ sed -E 's/(sk|pk|rk|whsec)_(live|test)_[A-Za-z0-9_]{6,}/[R]/g; s/gsk_[A-Za-z0-9]+/[R]/g; s/AIza[0-9A-Za-z_-]{20,}/[R]/g; s/((pass(word)?|passwd|secret|token|api_?key|pwd|auth_?key|salt)[A-Za-z_]*["'"'"' ]*(=>|=|:) *["'"'"']?)[^"'"'"' ,;)]{4,}/\1[R]/Ig; s/(define\( *["'"'"'](DB_PASSWORD|AUTH_KEY|SECURE_AUTH_KEY|LOGGED_IN_KEY|NONCE_KEY|[A-Z_]*SALT)["'"'"'] *, *["'"'"'])[^"'"'"']*/\1[R]/g'; }
dump(){ [ -f "$1" ] || { echo "#### (missing) $1"; return; }; echo; echo "######## FILE $1 ($(stat -c%s "$1") bytes, md5 $(md5sum <"$1"|cut -c1-32))"; head -c ${2:-160000} "$1"; echo; echo "######## END $1"; }
SITES="digitalenvisioned.net shop members leads f1 claw funnel aitb tools factory lm 3d business moneysites go hot free-pack opinion ads optimizer affiliate"
for s in $SITES; do [ "$s" = digitalenvisioned.net ] && h=$s || h=$s.digitalenvisioned.net; R=$D/$h/public_html; O=$OPS/r-$K-$s.txt
{ echo "== SITE $h"; echo "== ls domain dir"; ls -la $D/$h 2>&1; echo "== ls docroot"; ls -la $R 2>&1 | head -80
  for f in .htaccess robots.txt llms.txt; do dump $R/$f 20000; done; dump $R/sitemap.xml 8000
  for f in index.html index.php; do dump $R/$f; done
  [ "$s" = digitalenvisioned.net ] && dump $R/ai-receptionist/index.php
  echo "== files with head markup (outside uploads/vendor)"
  for dir in $R $D/$h/app $D/$h/src $D/$h/private; do [ -d $dir ] || continue
    find $dir -maxdepth 3 -type f \( -name '*.php' -o -name '*.html' -o -name '*.js' -o -name '*.ejs' -o -name '*.txt' -o -name '*.xml' \) -size -200k \
     -not -path '*/node_modules/*' -not -path '*/vendor/*' -not -path '*/wp-*' -not -path '*/uploads/*' -not -path '*/alabama/*' -not -path '*/town/*' -not -path '*/.git/*' -not -path '*/.ops-*' -not -path '*/backup*' 2>/dev/null; done | sort -u > /tmp/p3f.$$
  echo "candidate files: $(wc -l </tmp/p3f.$$)"; cat /tmp/p3f.$$ | head -200
  xargs -r -d '\n' grep -lE '<title|og:title|ld\+json|<h1|<meta name=.?description' < /tmp/p3f.$$ 2>/dev/null | grep -vE '/(index\.(html|php))$' | head -12 | while read -r f; do dump "$f" 120000; done
} </dev/null 2>&1 | red > "$O"; rm -f /tmp/p3f.$$; done
# private app dirs
O=$OPS/r-$K-apps.txt
{ echo "== home"; ls -la $H
  for f in $H/funnelforge/layout.php $H/funnelforge/boot.php; do dump $f; done
  for dir in $H/workforge* $H/wf_private* $H/f1* $D/f1.digitalenvisioned.net/private $H/go_app $D/leads.digitalenvisioned.net/app; do [ -e "$dir" ] && { echo "== $dir"; find "$dir" -maxdepth 2 | head -40; }; done
  grep -rlE '<title|og:title|ld\+json' $H/funnelforge $H/de_shared $D/leads.digitalenvisioned.net/app $D/go.digitalenvisioned.net/app 2>/dev/null | head -20
  WFP=$(grep -ho "define('WF_PRIVATE'[^)]*)" $D/f1.digitalenvisioned.net/public_html/*.php 2>/dev/null | head -1); echo "WF_PRIVATE: $WFP"
} 2>&1 | red > "$O"
# claw node app
O=$OPS/r-$K-clawapp.txt
{ C=$D/claw.digitalenvisioned.net; ls -la $C $C/* 2>&1 | head -80
  find $H -maxdepth 4 -name package.json -not -path '*/node_modules/*' 2>/dev/null
  for p in $(find $H -maxdepth 4 -name package.json -not -path '*/node_modules/*' 2>/dev/null); do dd=$(dirname $p); echo "== $dd"; ls -la $dd | head -40; head -c 3000 $p; echo; grep -rn --include=*.js --include=*.mjs --include=*.cjs --include=*.ts -E "express\.static|sendFile|robots\.txt|sitemap\.xml|llms|app\.listen|PORT" $dd --exclude-dir=node_modules 2>/dev/null | head -40; done
  ps aux 2>/dev/null | grep -i node | grep -v grep | head
} 2>&1 | red > "$O"
# claims + Montgomery + noindex grep
O=$OPS/r-$K-claims.txt
{ ROOTS=""; for s in $SITES; do [ "$s" = digitalenvisioned.net ] && h=$s || h=$s.digitalenvisioned.net; ROOTS="$ROOTS $D/$h/public_html"; done
  for pat in 'Valued at' 'Trusted by local' '#1 in local' 'activated in your name' 'LIVE 2026' 'ACT NOW' 'leader of digital products' '24/7' 'Subscription form is not available' 'noindex' 'X-Robots-Tag' 'AggregateRating' '"highPrice"' 'Guide.s Here'; do echo "==== PATTERN: $pat"
   grep -rnF --include=*.html --include=*.php --include=*.js --include=*.ejs --include=*.htaccess -e "$pat" $ROOTS $H/funnelforge $D/leads.digitalenvisioned.net/app $D/go.digitalenvisioned.net/app $D/members.digitalenvisioned.net/src 2>/dev/null | grep -vE '/(alabama|town|wp-content|wp-includes|wp-admin|node_modules|vendor|backups?|\.ops-[0-9]+)/' | cut -c1-400 | head -60; done
  echo "==== Montgomery counts (excluding alabama/, town/, wp core)"
  grep -rcF --include=*.html --include=*.php --include=*.js --include=*.txt --include=*.xml Montgomery $ROOTS $H/funnelforge $D/leads.digitalenvisioned.net/app $D/go.digitalenvisioned.net/app $D/members.digitalenvisioned.net/src 2>/dev/null | grep -v ':0$' | grep -vE '/(alabama|town|wp-content|wp-includes|wp-admin|node_modules|vendor|backups?|\.ops-[0-9]+)/' | head -150
  echo "==== guardian"; php $H/de_guardian/rebaseline.php --list 2>&1 | head -80
  echo "==== tools"; which git curl php wp node; php -v | head -1; git --version
} 2>&1 | red > "$O"
# free-pack WordPress
O=$OPS/r-$K-wp.txt
{ cd $D/free-pack.digitalenvisioned.net/public_html && {
  wp plugin list --format=csv 2>&1; wp theme list --format=csv 2>&1
  echo "== front"; wp option get show_on_front; FP=$(wp option get page_on_front 2>/dev/null); echo "page_on_front=$FP"; wp option get blogname; wp option get blogdescription
  wp post list --post_type=page --fields=ID,post_title,post_name,post_status --format=csv 2>&1 | head -60
  echo "== grep message in plugins/themes"; grep -rlF "Subscription form is not available" wp-content/plugins wp-content/themes 2>/dev/null | head
  echo "== pages containing the form markers"; wp db query "SELECT ID,post_type,post_status,post_title FROM $(wp db prefix 2>/dev/null)posts WHERE post_status='publish' AND (post_content LIKE '%newsletter%' OR post_content LIKE '%subscri%' OR post_content LIKE '%[mc4wp%' OR post_content LIKE '%mailpoet%' OR post_content LIKE '%wp:%form%')" 2>&1 | head -40
  echo "== front content"; wp post get $FP --field=post_content 2>&1 | head -c 60000
  echo; echo "== front meta keys"; wp post meta list $FP --format=csv --fields=meta_key 2>&1 | head -60
  echo "== elementor form bits"; wp post meta get $FP _elementor_data 2>/dev/null | grep -oE '.{300}(subscri|newsletter|form_id|list_id).{300}' | head -20
  echo "== newsletter-ish options"; wp option list --search='*newsletter*' --fields=option_name --format=csv 2>&1 | head -40; wp option list --search='*mailpoet*' --fields=option_name --format=csv 2>&1 | head -20; wp option list --search='*mc4wp*' --fields=option_name --format=csv 2>&1|head
  echo "== tables"; wp db query "SHOW TABLES" 2>&1 | grep -iE 'newsletter|mailpoet|subscri|form|lead|fluent|tnp' | head -40
  echo "== users sitemap / robots"; wp option get blog_public; }
} </dev/null 2>&1 | red > "$O"
ls -la $OPS | grep "r-$K" ; echo RECON-DONE
