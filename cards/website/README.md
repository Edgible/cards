# website

A public site, an open analytics script, a locked analytics dashboard, and a locked uptime monitor.

`site` is nginx serving your files, open to anyone. `analytics` is the Umami tracking script, also open. `umami` is that same process with its dashboard behind an org login, and it needs Postgres. Those three share the place `web`, so they run on one serving device. `status` is Uptime Kuma behind an org login, on the place `monitor`, which can be a second serving device. A monitor on the same machine as the site cannot report that machine going down.

Umami and Uptime Kuma start from the Compose files those projects publish. The card lists the edits: bind the host port to loopback, and replace Umami's sample secrets. [tailor.sh](tailor.sh) applies that list. The site has no upstream Compose file, so `docker-compose.yml` and the sample `public/index.html` sit next to this card, and the script leaves them alone.

Fetch the gold files into `~/umami` and `~/uptime-kuma`, then run the script on the machine that will start the containers. It writes `~/umami/.env` when that file is missing. It does not store the generated values.

```bash
bash tailor.sh
```

Other directories are `bash tailor.sh ~/umami ~/uptime-kuma`.

The card is [card.yml](card.yml).
