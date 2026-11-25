# Setup ambienti Laravel

Comandi [navi](https://github.com/denisidoro/navi) per creare progetti Laravel con Sail che
girano in parallelo: ognuno ha il suo dominio `<progetto>.localhost` dietro lo stesso
nginx-proxy e le sue porte per Vite, MySQL e Mailpit.

Provato con Laravel 12, PHP 8.5, UIkit 3, Pest 4.

## Prerequisiti

- Docker con Compose e navi (provato con navi 2.24.0)
- nginx-proxy attivo sulla porta 80 e collegato alla rete Docker esterna `proxy`
- immagine `sail-8.5/app` già presente in locale: la crea la build di un qualsiasi progetto
  Sail con PHP 8.5. I comandi usano `--pull never`, quindi senza immagine si fermano
- questa cartella in `~/dev/www/_setup`: il percorso è scritto nei comandi

PHP, Composer e Node sull'host non servono.

## Installazione

```bash
mkdir -p ~/.local/share/navi/cheats
ln -s ~/dev/www/_setup/laravel.cheat ~/.local/share/navi/cheats/laravel-setup.cheat
```

## Uso

```bash
navi --fzf-overrides '--no-sort' --query 'setup '
```

`--no-sort` mantiene l'ordine dei passi: senza, fzf li riordina per rilevanza.

I passi sono numerati `fase.variante.passo`. Si seguono le fasi in ordine crescente e, per
ogni fase, si sceglie **una sola variante**.

| Passi | Layer | Cosa fa |
|---|---|---|
| `0.0.1` | stato | mostra i passi fatti e mancanti di un progetto |
| `1.0.1` - `1.0.6` | base | porte, progetto, Sail (MySQL, Mailpit), dominio, migration |
| `2.0.1` - `2.0.4` | uikit | UIkit al posto di Tailwind, layout e welcome |
| `3.0.1` - `3.0.3` | pest | Pest 4 al posto di PHPUnit, `RefreshDatabase` |
| `4.0.1` - `4.0.3` | browser | pest-plugin-browser, Playwright e Chromium |
| `9.0.1` - `9.0.2` | git | repository e primo commit |

`uikit` e `browser` sono facoltativi; `browser` richiede `pest`. Le fasi 5-8 sono libere.

I passi vanno lanciati su un progetto nuovo: alcuni sostituiscono file dello skeleton
(`app.css`, `welcome.blade.php`, gli `ExampleTest`).

## Porte

`1.0.1` assegna a ogni progetto un indice N (massimo + 1) e lo scrive in `ports.tsv`.

| Servizio | Variabile | Porta |
|---|---|---|
| Vite | `VITE_PORT` | 5173 + N |
| MySQL | `FORWARD_DB_PORT` | 3306 + N |
| Mailpit SMTP | `FORWARD_MAILPIT_PORT` | 1025 + N |
| Mailpit dashboard | `FORWARD_MAILPIT_DASHBOARD_PORT` | 8025 + N |

La porta 80 non viene pubblicata: `compose.override.yaml` la toglie e collega il container
al proxy. Il `compose.yaml` di Sail resta intatto.

## Stato di un progetto

```bash
bash ~/dev/www/_setup/stato.sh <progetto>
```

- `ok`: il risultato del passo è presente
- `MANCA`: il layer è iniziato ma questo passo non risulta
- `--`: verifica che non lascia traccia
- `non installato`: nessun passo del layer fatto

Legge soltanto. `1.0.5` controlla che esista il volume MySQL, non che le migration siano passate.

## Aggiungere un layer

1. In `laravel.cheat`, una sezione con un tag suo. La riga `@` riusa la variabile `<progetto>`:

   ```
   % laravel, setup, react
   @ laravel, setup, base

   # 2.1.1 react: Descrizione del passo
   cd ~/dev/www/<progetto> && ...
   ```

2. Un'alternativa a un layer esistente prende la variante successiva della stessa fase (`2.1`);
   un layer nuovo prende una fase libera.
3. I file da copiare vanno in `stubs/<layer>/`. Nei comandi non scrivere `<parola>` se non è una
   variabile: navi la chiederebbe.
4. In `stato.sh`, un blocco `layer` con una condizione seguita da `passo` per ogni passo.

## Rimuovere un progetto

Non c'è un comando. Dalla cartella del progetto, `./vendor/bin/sail down -v` rimuove container
e volumi (**cancella il database**); poi va tolta la riga da `ports.tsv`.

## Limiti noti

- **Laravel 13:** `1.0.2` la propone, ma non è provata. `3.0.1` è fissato a Pest 4, perché Pest 5
  non è installabile su Laravel 12 (richiede `symfony/process` 8).
- **Clone di un progetto:** `.env.example` contiene nome, dominio e porte, ma non la
  configurazione di DB e mail, che `sail:install` scrive solo in `.env`.
- **Browser test:** Chromium sta in `node_modules` del progetto (circa 700 MB) e va riscaricato
  se la cartella viene cancellata.
- **Messaggio di commit** (`9.0.2`): niente apostrofi.
