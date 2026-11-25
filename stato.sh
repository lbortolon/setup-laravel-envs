#!/usr/bin/env bash
# Mostra quali passi di laravel.cheat risultano fatti in un progetto. Solo lettura.
# Uso: stato.sh nome-progetto
#
# Ogni passo è una condizione seguita da "passo": l'esito è quello della condizione.

progetto=$1
setup=$(dirname "$(readlink -f "$0")")
dir=$HOME/dev/www/$progetto
incompleti=0

ha() { grep -q -- "$2" "$1" 2>/dev/null; }

layer() {
    chiudi
    titolo=$1 righe=() fatti=0 mancanti=0
}

passo() {
    local esito=$?
    if [ $esito -eq 0 ]; then
        righe+=("  ok     $1  $2")
        fatti=$((fatti + 1))
    else
        righe+=("  MANCA  $1  $2")
        mancanti=$((mancanti + 1))
    fi
}

# Passo di verifica o non controllabile: non conta come fatto né come mancante
nota() { righe+=("  --     $1  $2"); }

# Un layer senza nessun passo fatto è una scelta, non un errore
chiudi() {
    [ -n "$titolo" ] || return
    if [ $fatti -eq 0 ]; then
        echo "$titolo: non installato"
    else
        echo "$titolo"
        printf '%s\n' "${righe[@]}"
        [ $mancanti -eq 0 ] || incompleti=1
    fi
}

N=$(awk -v n="$progetto" '!/^#/ && $1 == n { print $2 }' "$setup/ports.tsv")

layer '1.0 base'
[ -n "$N" ]
passo 1.0.1 'Indice porte riservato'

if ! cd "$dir" 2>/dev/null; then
    false
    passo 1.0.2 "Progetto creato ($dir non esiste)"
    chiudi
    exit 1
fi

[ -e artisan ] && [ -d vendor/laravel/framework ]
passo 1.0.2 'Progetto creato'

ha compose.yaml 'mysql:' && ha compose.yaml 'mailpit:'
passo 1.0.3 'Sail con MySQL e Mailpit'

[ -e compose.override.yaml ] && ha .env "^VIRTUAL_HOST=$progetto.localhost\$" && ha .env "^VITE_PORT=$((5173 + N))\$" && ha .env.example '^VIRTUAL_HOST='
passo 1.0.4 'Dominio, proxy e porte (.env e .env.example)'

if docker info >/dev/null 2>&1; then
    docker volume inspect "${progetto}_sail-mysql" >/dev/null 2>&1
    passo 1.0.5 'Container avviati almeno una volta (volume MySQL)'
else
    nota 1.0.5 'Docker non raggiungibile'
fi
nota 1.0.6 "Adesso http://$progetto.localhost risponde $(curl -sS -m 5 -o /dev/null -w '%{http_code}' "http://$progetto.localhost" 2>/dev/null)"

layer '2.0 uikit'
ha package.json '"uikit"' && ! ha package.json tailwindcss && [ -d node_modules/uikit ]
passo 2.0.1 'Pacchetti npm'

ha resources/js/app.js uikit && ha resources/css/app.css uikit && ! ha vite.config.js tailwindcss
passo 2.0.2 'CSS, JS e Vite'

ha resources/views/components/layout.blade.php uk-
passo 2.0.3 'Layout'

ha public/build/manifest.json resources/css/app.css && grep -qs uk-navbar public/build/assets/*.css
passo 2.0.4 'Build con UIkit'

layer '3.0 pest'
ha composer.json '"pestphp/pest"' && ! ha composer.json '"phpunit/phpunit"'
passo 3.0.1 'Pest al posto di PHPUnit'

ha tests/Pest.php '^ *->use(RefreshDatabase'
passo 3.0.2 'Pest.php con RefreshDatabase'
nota 3.0.3 'Test: lancia 3.0.3'

layer '4.0 browser'
ha composer.json '"pestphp/pest-plugin-browser"' && ha package.json '"playwright"' && compgen -G 'node_modules/playwright-core/.local-browsers/chromium-*' >/dev/null
passo 4.0.1 'Plugin, Playwright e Chromium'

ha tests/Pest.php "'Browser'" && ha phpunit.xml tests/Browser && ha .gitignore tests/Browser/Screenshots && [ -d tests/Browser ]
passo 4.0.2 'Testsuite Browser'
nota 4.0.3 'Browser test: lancia 4.0.3'

layer '9.0 git'
[ -e .git ]
passo 9.0.1 'Repository'

[ -e .git ] && git rev-parse -q --verify HEAD >/dev/null 2>&1
passo 9.0.2 'Primo commit'

chiudi
exit $incompleti
