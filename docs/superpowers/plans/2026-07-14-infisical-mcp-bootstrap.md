# Infisical Bootstrap + MCP Server Migration Implementation Plan

**Superseded and reversed (2026-07-18):** everything this plan set up has
since been undone. `Homepage.SecretsStore` replaced Infisical as the actual
secrets backend (`proxmox/docs/superpowers/specs/2026-07-14-secrets-service-design.md`),
the 7 MCP servers with real tokens were migrated there, and `linkedin-mcp` —
the one server this plan bootstrapped that never had a real token — was
removed outright along with the `mkInfisicalRunCmd`/`mkInfisicalClaudeMcp`
helpers this plan introduced. Infisical (CT 206) itself is being
decommissioned. Kept for historical context only; do not execute.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `homelab` project in the self-hosted Infisical instance and migrate the local MCP servers (used by both Claude Code and OpenCode on this workstation) from reading credentials off flat files under `/mnt/stags/.config/mcp-tokens/` to fetching them from Infisical via `infisical run`.

**Architecture:** A single Infisical machine identity (`mcp-servers`, Universal Auth, read-only, scoped to `/mcp/**`) authenticates each MCP server process at launch. A shared Nix helper function (`mkInfisicalRunCmd`) builds the shell wrapper — login, fetch a token, `exec infisical run ... -- <binary>` — reused across both `~/.claude.json`'s `mcpServers` block and `~/.config/opencode/config.json`'s `mcp` block, both declared in `nixos/home/stags/default.nix`.

**Tech Stack:** Nix / home-manager, Infisical CLI (`pkgs.infisical`, nixpkgs v0.41.90), self-hosted Infisical at `https://infisical.virtualdino.com`.

## Global Constraints

- Only migrate MCP servers that currently read a real secret: `forgejo`, `todo`, `prowlarr`, `proxmox`, `radarr`, `sonarr`, `linkedin`, `grammarly`. `victorialogs`, `mediawatch`, `jobhunt` have no secret today (fixed public URLs, no token) — leave them untouched (YAGNI).
- The `mcp-servers` identity gets **Read only**, scoped to `/mcp/**` — it must never be able to read `/ci/*` or other folders created in later phases.
- Every change to `nixos/home/stags/default.nix` must be applied with `sudo nixos-rebuild switch --flake <this checkout's absolute path>#xps15` and verified before moving to the next task. This work happens in a git worktree — use the worktree's own path, not `/home/stags/Source/nixos`, until the branch is merged.
- Design doc of record: `proxmox/docs/superpowers/specs/2026-07-14-infisical-integration-design.md`.

---

### Task 1: Infisical bootstrap (org, project, folders, role, identity) — manual

This task can't be scripted: it includes creating your own admin account and password, which shouldn't be automated on your behalf. Do this via the web UI at `https://infisical.virtualdino.com`.

**Files:** none (Infisical server-side state only).

- [ ] **Step 1: Create the org admin account**

  Visit `https://infisical.virtualdino.com`, complete the first-run signup flow (this becomes the instance's first admin account and org). Use your own credentials/password manager — do not hand these to any automated step.

- [ ] **Step 2: Create the `homelab` project**

  In the Infisical UI: Projects → Add New Project → name it `homelab`. Accept the default environments it creates (`dev`, `staging`, `prod`) — leaving `staging`/`prod` empty is harmless, and scripting them away isn't worth the extra API calls. This plan only uses `dev`.

- [ ] **Step 3: Create the folder skeleton for this phase**

  Inside the `homelab` project, `dev` environment, create these folders (Secrets → dev environment → the `+ folder` control at each path):
  ```
  /mcp/forgejo
  /mcp/todo
  /mcp/prowlarr
  /mcp/proxmox
  /mcp/radarr
  /mcp/sonarr
  /mcp/linkedin
  /mcp/grammarly
  ```
  Do not create folders for `victorialogs`, `mediawatch`, `jobhunt`, or any `/ci/*` path — out of scope for this phase.

- [ ] **Step 4: Create a custom project role scoped to `/mcp/**`**

  Project Settings → Access Control → Project Roles → Create Custom Role:
  - Name: `mcp-servers-reader`
  - Permission: **Secrets → Read**, Environment: `dev`, Secret Path: `/mcp/**`

  This is what makes the identity's access folder-scoped instead of project-wide.

- [ ] **Step 5: Create the `mcp-servers` machine identity**

  Organization Settings → Access Control → Identities → Create Identity:
  - Name: `mcp-servers`
  - Auth Method: Universal Auth
  - Leave Access Token TTL/Max TTL at defaults (30 days) — Task 4's wrapper re-authenticates on every launch, so token expiry between launches doesn't matter.

  Then: Create Client Secret (default TTL = never expires) — copy both the **Client ID** and **Client Secret** somewhere temporary; you'll write them to disk in Step 7.

- [ ] **Step 6: Attach the identity to the project with the custom role**

  In the `homelab` project → Project Settings → Access Control → Machine Identities → Add Identity → select `mcp-servers` → role `mcp-servers-reader`.

- [ ] **Step 7: Save the bootstrap credential to disk**

  ```bash
  mkdir -p /mnt/stags/.config/mcp-tokens
  echo -n '<client id from step 5>' > /mnt/stags/.config/mcp-tokens/infisical-client-id
  echo -n '<client secret from step 5>' > /mnt/stags/.config/mcp-tokens/infisical-client-secret
  chmod 600 /mnt/stags/.config/mcp-tokens/infisical-client-id /mnt/stags/.config/mcp-tokens/infisical-client-secret
  ```

- [ ] **Step 8: Record the project ID**

  In the Infisical UI, open the `homelab` project → Project Settings → copy the **Project ID** (also visible in the URL: `.../project/<PROJECT_ID>/secrets/...`). You'll need this literal value in Task 4. Write it down now.

---

### Task 2: Verify the Infisical CLI's flags (no install — invoked via `nix run` per launch)

Decision: `infisical` is **not** added to `home.packages`. Every wrapper script in Tasks 4-5 invokes it as `nix run nixpkgs#infisical -- <args>` instead of a bare `infisical`, so no rebuild is needed just to make the binary available (`nix run` fetches/caches it from the Nix store on first use, no sudo required). This does **not** remove the rebuild requirement from Tasks 4-6 — those tasks change `claudeMcpServers` and the OpenCode config block, which this repo's existing activation script only materializes into `~/.claude.json` / `~/.config/opencode/config.json` during `nixos-rebuild switch` (see the comment at `default.nix:837-841` explaining why it merges via `jq` on every switch — bypassing that would just get silently overwritten next rebuild).

**Files:** none — verification only, already completed directly in this session:

```bash
nix run nixpkgs#infisical -- --version
# infisical version 0.41.90

nix run nixpkgs#infisical -- login --help | grep -A5 -i "client-id\|client-secret\|method\|silent\|plain"
# --client-id, --client-secret, --method (default "user"), --plain, --silent all present

nix run nixpkgs#infisical -- run --help | grep -E -- '--(projectId|env|path|token)'
# --projectId, --env, --path, --token all present
```

All flags this plan's `mkInfisicalRunCmd`/`mkInfisicalGrammarlyCmd` templates (Task 4, Task 5) rely on are confirmed present in v0.41.90. Nothing further to do for this task.

---

### Task 3: Seed secret values into Infisical from the existing token files — done

Completed directly via the Infisical REST API (using the temporary `claude-bootstrap` org-admin identity from Task 1, since it has write access, unlike the read-only `mcp-servers` identity). All 13 secrets were set under project `e0945d85-c9f4-4d1e-a1cf-611295ba6613`, environment `dev`:

`FORGEJO_TOKEN`, `FORGEJO_URL` → `/mcp/forgejo`; `TODO_URL` → `/mcp/todo`; `PROWLARR_URL`, `PROWLARR_API_KEY` → `/mcp/prowlarr`; `PROXMOX_HOST`, `PROXMOX_TOKEN_ID`, `PROXMOX_TOKEN_SECRET` → `/mcp/proxmox`; `RADARR_URL`, `RADARR_API_KEY` → `/mcp/radarr`; `SONARR_URL`, `SONARR_API_KEY` → `/mcp/sonarr`; `GRAMMARLY_COOKIES` → `/mcp/grammarly`.

`linkedin` was skipped — `/mnt/stags/.config/mcp-tokens/linkedin` doesn't exist today (the existing config already reads a missing file, so `LINKEDIN_ACCESS_TOKEN` is currently empty). Nothing to migrate until a real token exists; the `/mcp/linkedin` folder from Task 1 is ready for whenever one does.

**Verified end-to-end**: logged in as the real `mcp-servers` (read-only) identity and ran `infisical run --domain=https://infisical.virtualdino.com --projectId=e0945d85-c9f4-4d1e-a1cf-611295ba6613 --env=dev --path=/mcp/proxmox -- sh -c '...'` — confirmed `PROXMOX_HOST`, `PROXMOX_TOKEN_ID`, `PROXMOX_TOKEN_SECRET` all inject correctly. Also confirmed the identity is denied write access (403 on a test `POST /api/v3/secrets/raw/...`), proving the read-only scoping from Task 1 actually holds.

**Important flag discovered here**: `infisical run` does **not** inherit `--domain` from a prior `infisical login` call — each invocation needs its own `--domain=https://infisical.virtualdino.com`, or it silently defaults to the public `app.infisical.com` and fails with `status-code=403 message="invalid signature"`. Task 4/5's `mkInfisicalRunCmd`/`mkInfisicalGrammarlyCmd` templates below have already been corrected for this.

---

### Task 4: Nix helper + migrate the standard single/multi-secret MCP servers

**Files:**
- Modify: `nixos/home/stags/default.nix:108-188` (the `claudeMcpServers` let-binding)

**Interfaces:**
- Produces: `mkInfisicalRunCmd { path, binary, extraArgs ? "" }` → shell script string; `mkInfisicalClaudeMcp { path, binary, extraArgs ? "" }` → attrset in Claude's `mcpServers` shape. Both consumed again in Task 5.

- [ ] **Step 1: Add the helper functions**

  In the `let` block of `nixos/home/stags/default.nix`, immediately before `claudeMcpServers = {` (currently line 113), add:

  ```nix
  infisicalTokensPath = "/mnt/stags/.config/mcp-tokens";
  infisicalDomain = "https://infisical.virtualdino.com";
  infisicalProjectId = "e0945d85-c9f4-4d1e-a1cf-611295ba6613"; # homelab project, created in Task 1

  # infisical isn't a home.package (Task 2) — invoked via `nix run` so no
  # rebuild is needed just to get the binary. Cached after first fetch.
  infisicalBin = "nix run nixpkgs#infisical --";

  # Logs in as the read-only `mcp-servers` Infisical identity and re-execs
  # `binary` with secrets from `path` injected as env vars. `path` must be
  # a folder the mcp-servers-reader role can read (Task 1, Step 4).
  mkInfisicalRunCmd = { path, binary, extraArgs ? "" }: ''
    INFISICAL_CLIENT_ID=$(cat ${infisicalTokensPath}/infisical-client-id)
    INFISICAL_CLIENT_SECRET=$(cat ${infisicalTokensPath}/infisical-client-secret)
    INFISICAL_TOKEN=$(${infisicalBin} login --domain=${infisicalDomain} --method=universal-auth --client-id="$INFISICAL_CLIENT_ID" --client-secret="$INFISICAL_CLIENT_SECRET" --plain --silent)
    exec ${infisicalBin} run --domain=${infisicalDomain} --token="$INFISICAL_TOKEN" --projectId=${infisicalProjectId} --env=dev --path=${path} -- ${binary} ${extraArgs}
  '';

  mkInfisicalClaudeMcp = { path, binary, extraArgs ? "" }: {
    type = "stdio";
    command = "sh";
    args = [ "-c" (mkInfisicalRunCmd { inherit path binary extraArgs; }) ];
  };
  ```

  `infisicalProjectId` above already has the real project ID filled in (`e0945d85-c9f4-4d1e-a1cf-611295ba6613`) — no placeholder left to replace.

- [ ] **Step 2: Rewrite the seven standard entries in `claudeMcpServers`**

  Replace these six entries (`forgejo`, `todo`, `prowlarr`, `proxmox`, `radarr`, `sonarr`) — leave `victorialogs`, `mediawatch`, `jobhunt`, the `cloudflare*` entries, and `grammarly`/`linkedin` untouched for now (grammarly and linkedin are handled in Task 5):

  ```nix
    forgejo = mkInfisicalClaudeMcp {
      path = "/mcp/forgejo";
      binary = "forgejo-mcp";
    };
    todo = mkInfisicalClaudeMcp {
      path = "/mcp/todo";
      binary = "todo-mcp";
    };
    victorialogs = {
      type = "stdio";
      command = "victorialogs-mcp";
    };
    mediawatch = {
      type = "stdio";
      command = "mediawatch-mcp";
      env.MEDIAWATCH_URL = "https://mediawatch.virtualdino.com";
    };
    jobhunt = {
      type = "stdio";
      command = "jobhunt-mcp";
      env.JOBHUNT_URL = "https://jobhunt.virtualdino.com";
    };
    prowlarr = mkInfisicalClaudeMcp {
      path = "/mcp/prowlarr";
      binary = "prowlarr-mcp";
    };
    proxmox = mkInfisicalClaudeMcp {
      path = "/mcp/proxmox";
      binary = "proxmox-mcp";
    };
    radarr = mkInfisicalClaudeMcp {
      path = "/mcp/radarr";
      binary = "radarr-mcp";
    };
    sonarr = mkInfisicalClaudeMcp {
      path = "/mcp/sonarr";
      binary = "sonarr-mcp";
    };
  ```

  (`forgejo-mcp`'s old wrapper also set `FORGEJO_URL` — that's not a secret, but it was already seeded into `/mcp/forgejo` alongside `FORGEJO_TOKEN` in Task 3, so `mkInfisicalRunCmd` picks it up the same way with no extra step needed.)

- [ ] **Step 3: Rebuild**

  ```bash
  sudo nixos-rebuild switch --flake <worktree-path>#xps15
  ```

- [ ] **Step 4: Verify one server manually before trusting Claude Code's wiring**

  ```bash
  jq -r '.mcpServers.proxmox.args[1]' ~/.claude.json | bash
  ```

  This runs the exact generated wrapper script directly. Expected: it starts `proxmox-mcp` and blocks waiting for stdio input (Ctrl+C to exit) — no auth errors printed to stderr first.

- [ ] **Step 5: Verify through Claude Code itself**

  Restart Claude Code, then run a tool call that hits a migrated server, e.g. list Proxmox containers via the `proxmox` MCP tools. Expected: returns real data, confirming the token from Infisical actually authenticated against the Proxmox API.

- [ ] **Step 6: Commit**

  ```bash
  git add home/stags/default.nix
  git commit -m "Migrate forgejo/todo/prowlarr/proxmox/radarr/sonarr MCP servers to Infisical"
  ```

---

### Task 5: grammarly-mcp (file-based secret) + mirror everything into OpenCode's config

**Files:**
- Modify: `nixos/home/stags/default.nix:108-188` (`claudeMcpServers`, `grammarly`/`linkedin` entries)
- Modify: `nixos/home/stags/default.nix:854-949` (the `home.file.".config/opencode/config.json"` block)

**Interfaces:**
- Consumes: `mkInfisicalRunCmd`, `mkInfisicalClaudeMcp` from Task 4.
- Produces: `mkInfisicalGrammarlyCmd path` → shell script string (grammarly needs a cookie *file*, not env vars, so it can't reuse `mkInfisicalRunCmd` directly).

- [ ] **Step 1: Add the grammarly-specific helper**

  Add next to `mkInfisicalRunCmd` in the same `let` block:

  ```nix
  # grammarly-mcp takes a --cookies-file path, not env vars, so the fetched
  # secret has to be materialized to a temp file before exec'ing it.
  mkInfisicalGrammarlyCmd = path: ''
    INFISICAL_CLIENT_ID=$(cat ${infisicalTokensPath}/infisical-client-id)
    INFISICAL_CLIENT_SECRET=$(cat ${infisicalTokensPath}/infisical-client-secret)
    INFISICAL_TOKEN=$(${infisicalBin} login --domain=${infisicalDomain} --method=universal-auth --client-id="$INFISICAL_CLIENT_ID" --client-secret="$INFISICAL_CLIENT_SECRET" --plain --silent)
    COOKIES_FILE=$(mktemp)
    trap 'rm -f "$COOKIES_FILE"' EXIT
    ${infisicalBin} run --domain=${infisicalDomain} --token="$INFISICAL_TOKEN" --projectId=${infisicalProjectId} --env=dev --path=${path} -- sh -c 'printf %s "$GRAMMARLY_COOKIES"' > "$COOKIES_FILE"
    exec grammarly-mcp --cookies-file "$COOKIES_FILE"
  '';
  ```

- [ ] **Step 2: Update `grammarly` and `linkedin` in `claudeMcpServers`**

  ```nix
    grammarly = {
      type = "stdio";
      command = "sh";
      args = [ "-c" (mkInfisicalGrammarlyCmd "/mcp/grammarly") ];
    };
    linkedin = mkInfisicalClaudeMcp {
      path = "/mcp/linkedin";
      binary = "linkedin-mcp";
    };
  ```

  (`linkedin` will still get an empty `LINKEDIN_ACCESS_TOKEN` until a real token is set in Infisical — same behavior as today, just sourced differently.)

- [ ] **Step 3: Mirror all eight migrated servers into the OpenCode `mcp` block**

  In the `home.file.".config/opencode/config.json"` block, replace the `forgejo`, `todo`, `prowlarr`, `proxmox`, `radarr`, `sonarr`, `grammarly`, `linkedin` entries (OpenCode's shape wraps the command in a list rather than a bare string — this must change too, or OpenCode keeps reading the deleted flat files after Task 6):

  ```nix
        forgejo = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/forgejo"; binary = "forgejo-mcp"; }) ];
        };
        todo = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/todo"; binary = "todo-mcp"; }) ];
        };
        victorialogs = {
          type = "local";
          command = [ "victorialogs-mcp" ];
        };
        mediawatch = {
          type = "local";
          command = [ "mediawatch-mcp" ];
          environment.MEDIAWATCH_URL = "https://mediawatch.virtualdino.com";
        };
        jobhunt = {
          type = "local";
          command = [ "jobhunt-mcp" ];
          environment.JOBHUNT_URL = "https://jobhunt.virtualdino.com";
        };
        prowlarr = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/prowlarr"; binary = "prowlarr-mcp"; }) ];
        };
        proxmox = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/proxmox"; binary = "proxmox-mcp"; }) ];
        };
        radarr = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/radarr"; binary = "radarr-mcp"; }) ];
        };
        sonarr = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/sonarr"; binary = "sonarr-mcp"; }) ];
        };
        grammarly = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalGrammarlyCmd "/mcp/grammarly") ];
        };
        linkedin = {
          type = "local";
          command = [ "sh" "-c" (mkInfisicalRunCmd { path = "/mcp/linkedin"; binary = "linkedin-mcp"; }) ];
        };
  ```

  Leave the `cloudflare*` entries untouched.

- [ ] **Step 4: Rebuild**

  ```bash
  sudo nixos-rebuild switch --flake <worktree-path>#xps15
  ```

- [ ] **Step 5: Verify grammarly's cookie file materializes correctly**

  ```bash
  jq -r '.mcpServers.grammarly.args[1]' ~/.claude.json > /tmp/grammarly-test.sh
  bash -x /tmp/grammarly-test.sh 2>&1 | grep -A1 COOKIES_FILE | head -5
  ```

  Expected: shows a `mktemp`-generated path being created and passed via `--cookies-file`, no "file not found" errors.

- [ ] **Step 6: Commit**

  ```bash
  git add home/stags/default.nix
  git commit -m "Migrate grammarly/linkedin MCP servers to Infisical, mirror all changes into OpenCode config"
  ```

---

### Task 6: Retire the old flat-file tokens and do final end-to-end verification

**Files:** none in the repo — deletes files under `/mnt/stags/.config/mcp-tokens/`.

- [ ] **Step 1: Delete the now-redundant token files**

  Keep only `infisical-client-id` and `infisical-client-secret` — everything else has a Infisical-backed replacement as of Task 5.

  ```bash
  cd /mnt/stags/.config/mcp-tokens
  rm -f forgejo grammarly-cookies prowlarr prowlarr-url proxmox-host proxmox-token-id proxmox-token-secret radarr radarr-url sonarr sonarr-url todo-url
  ls
  ```

  Expected: only `infisical-client-id` and `infisical-client-secret` remain.

- [ ] **Step 2: Full rebuild from a clean state**

  ```bash
  sudo nixos-rebuild switch --flake <worktree-path>#xps15
  ```

- [ ] **Step 3: End-to-end verification across both clients**

  Restart Claude Code and OpenCode. For each of `forgejo`, `todo`, `prowlarr`, `proxmox`, `radarr`, `sonarr`, `grammarly`, run one real tool call through **both** clients and confirm it returns live data (not an auth error):

  - Claude Code: use each MCP server's tools directly (e.g. list Forgejo repos, list Proxmox containers, list Sonarr series).
  - OpenCode: same, via `opencode` session.

  `linkedin` will still fail/return empty — expected, no real token exists yet (same as before this migration).

- [ ] **Step 4: Final commit**

  ```bash
  cd /home/stags/Source/proxmox
  git log -1 --oneline docs/superpowers/specs/2026-07-14-infisical-integration-design.md
  ```

  (No code change here — just confirming the spec commit this plan implements is still the current one, for the record in the plan's completion notes.)
