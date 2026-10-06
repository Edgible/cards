# website

## Why

A site, the count of who read it, and a check that it is still up are usually three services someone else runs. This card keeps all three on machines you own. Strangers can open the site and the tracking script. The dashboard and the monitor ask for an org login.

## What

`site` is nginx serving your files, open to anyone. `analytics` is the Umami tracking script, also open. `umami` is that same process with its dashboard behind an org login, and it needs Postgres. Those three share the place `web`, so they run on one serving device. `status` is Uptime Kuma behind an org login, on the place `monitor`, which can be a second serving device. A monitor on the same machine as the site cannot report that machine going down.

Umami and Uptime Kuma start from the Compose files those projects publish. The site has no upstream Compose file, so `docker-compose.yml` sits next to this card. The sample page is [etc/index.html](etc/index.html). The card is [card.yml](card.yml).

## How

The card lists the edits. [tailor.sh](tailor.sh) applies that list. An existing `~/site/public/index.html` is left as it is. On the machine that will run the containers:

```bash
mkdir -p ~/site/public ~/umami ~/uptime-kuma
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/website/docker-compose.yml -o ~/site/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/umami-software/umami/master/docker-compose.yml -o ~/umami/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/louislam/uptime-kuma/master/compose.yaml -o ~/uptime-kuma/compose.yaml
if [ ! -f ~/site/public/index.html ]; then
  curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/website/etc/index.html -o ~/site/public/index.html
fi
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/website/tailor.sh -o ~/website-tailor.sh
bash ~/website-tailor.sh
```

The script writes `~/umami/.env` when that file is missing. It does not store the generated values. It exits if an expected edit is not in the file afterwards. Running it again is safe. Other directories are `bash ~/website-tailor.sh ~/umami ~/uptime-kuma`.
