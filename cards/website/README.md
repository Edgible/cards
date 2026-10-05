# website

A public site, an open analytics script, a locked analytics dashboard, and a locked uptime monitor.

`site` is nginx serving your files, open to anyone. `analytics` is the Umami tracking script, also open. `umami` is that same process with its dashboard behind an org login, and it needs Postgres. Those three share the place `web`, so they run on one serving device. `status` is Uptime Kuma behind an org login, on the place `monitor`, which can be a second serving device. A monitor on the same machine as the site cannot report that machine going down.

Umami and Uptime Kuma start from the Compose files those projects publish. The card lists the edits. [tailor.sh](tailor.sh) applies that list. The site has no upstream Compose file, so `docker-compose.yml` and the sample `public/index.html` sit next to this card. An existing `~/site/public/index.html` is left as it is.

On the machine that will run the containers:

```bash
mkdir -p ~/site/public ~/umami ~/uptime-kuma
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/website/docker-compose.yml -o ~/site/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/umami-software/umami/master/docker-compose.yml -o ~/umami/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/louislam/uptime-kuma/master/compose.yaml -o ~/uptime-kuma/compose.yaml
if [ ! -f ~/site/public/index.html ]; then
  curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/website/public/index.html -o ~/site/public/index.html
fi
curl -fsSL https://raw.githubusercontent.com/Edgible/cards/main/cards/website/tailor.sh -o ~/website-tailor.sh
bash ~/website-tailor.sh
```

The script writes `~/umami/.env` when that file is missing. It does not store the generated values. Other directories are `bash ~/website-tailor.sh ~/umami ~/uptime-kuma`.

The card is [card.yml](card.yml).
