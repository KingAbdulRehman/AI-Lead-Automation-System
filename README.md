# AI Lead Automation System

An end-to-end n8n workflow that receives leads, scores them with Google Gemini AI, saves results to Google Sheets, sends personalized Gmail emails, and posts Slack notifications — all automatically.

---

## Architecture Overview

```
Lead Form (HTML)
      │
      ▼ POST /webhook/lead-capture
┌─────────────────┐
│   Webhook Node  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Gemini AI Analysis     │  ← HTTP Request to Gemini 1.5 Flash
│  (Score + Quality)      │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Parse AI Response      │  ← Code Node (JavaScript)
│  (Build clean object)   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Save to Google Sheets  │  ← Append row with all fields
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│   Switch: Hot/Warm/Cold │  ← Route by AI quality score
└──┬────────┬─────────────┘
   │        │        │
   ▼        ▼        ▼
 Hot      Warm     Cold
 Email    Email    Email
   │        │        │
   └────────┴────────┘
            │
            ▼
┌─────────────────────────┐
│   Slack Notification    │  ← Lead summary + AI score
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│   Respond to Webhook    │  ← Return JSON to form
└─────────────────────────┘

[Error Trigger] → [Slack Error Alert]
```

---

## Prerequisites

- Docker Desktop installed
- Google account (for Sheets + Gmail)
- Slack workspace (with Incoming Webhooks or OAuth app)
- Gemini API key from Google AI Studio
- n8n account (optional, for cloud sync)

---

## Part 1 — Start n8n with Docker

### Step 1: Create your .env file

```bash
cp .env.example .env
```

Open `.env` and set:
```
N8N_ENCRYPTION_KEY=<generate with: openssl rand -hex 32>
```

### Step 2: Start n8n

```bash
docker compose up -d
```

### Step 3: Verify it's running

```bash
docker compose ps
docker compose logs -f n8n
```

Open your browser: **http://localhost:5678**

### Step 4: Create your n8n account

On first visit, create an admin account. Remember these credentials.

---

## Part 2 — Import the Workflow

### Method A: Import via UI (Recommended)

1. Log in to n8n at **http://localhost:5678**
2. Click **Workflows** in the left sidebar
3. Click **Add Workflow** → **Import from file**
4. Select `workflow.json` from this project
5. The workflow opens — you'll see red warning icons on nodes (credentials not yet set)
6. Click **Save** (top right)

### Method B: Import via CLI

```bash
docker exec -it ai-lead-automation-n8n n8n import:workflow --input=/tmp/workflow.json
```

---

## Part 3 — Configure Google Sheets (OAuth)

### Step 1: Create OAuth credentials in Google Cloud

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable: **Google Sheets API** and **Gmail API**
4. Go to **APIs & Services** → **Credentials**
5. Click **Create Credentials** → **OAuth 2.0 Client ID**
6. Application type: **Web application**
7. Add Authorized redirect URI:
   ```
   http://localhost:5678/rest/oauth2-credential/callback
   ```
8. Copy your **Client ID** and **Client Secret**

### Step 2: Add credential in n8n

1. In n8n: **Settings** → **Credentials** → **Add Credential**
2. Search: **Google Sheets OAuth2 API**
3. Paste your Client ID and Client Secret
4. Click **Connect** → Follow OAuth flow → Authorize
5. Name it: `Google Sheets OAuth`
6. Save

### Step 3: Update the Google Sheets node

1. Open the workflow
2. Click the **Save to Google Sheets** node
3. Select the credential you just created
4. Set Document ID to your Google Sheet ID (from the URL)
5. Set Sheet Name to `Sheet1` (or your sheet name)
6. Verify column mappings match headers from `google-sheets-setup.md`
7. Save

---

## Part 4 — Configure Gmail (OAuth)

### Step 1: Add Gmail credential in n8n

1. In n8n: **Settings** → **Credentials** → **Add Credential**
2. Search: **Gmail OAuth2**
3. Use the same Google OAuth Client ID and Secret (make sure Gmail API is enabled)
4. Click **Connect** → Authorize Gmail access
5. Name it: `Gmail OAuth`
6. Save

### Step 2: Update Gmail nodes in the workflow

1. Open the workflow
2. Click **Send Hot Lead Email** node
3. Select the `Gmail OAuth` credential
4. Verify the `sendTo` field uses `={{ $json.email }}`
5. Repeat for **Send Warm Lead Email** and **Send Cold Lead Email** nodes
6. Save

---

## Part 5 — Add Gemini API Key

### Step 1: Get your API key

1. Go to [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Click **Create API Key**
3. Select your project
4. Copy the key (starts with `AIza...`)

### Step 2: Create credential in n8n

1. In n8n: **Settings** → **Credentials** → **Add Credential**
2. Search: **HTTP Query Auth**
3. Set:
   - **Name:** `Gemini API Key`
   - **Name (Query Param):** `key`
   - **Value:** paste your API key
4. Save

### Step 3: Update the Gemini node

1. Open the workflow
2. Click **Analyze Lead with Gemini** node
3. Select `Gemini API Key` credential
4. The URL should be: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
5. Save

---

## Part 6 — Add Slack Credential

### Option A: Incoming Webhook (Simpler)

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Create new app → From scratch → name it `Lead Bot`
3. Add feature: **Incoming Webhooks** → Activate
4. Click **Add New Webhook to Workspace** → Select `#leads` channel
5. Copy the webhook URL

In n8n:
1. **Settings** → **Credentials** → **Add Credential**
2. Search: **Slack**
3. Authentication Method: **Webhook**
4. Paste the webhook URL
5. Name it: `Slack OAuth`
6. Save

### Option B: Slack OAuth App (Full access)

1. At [api.slack.com/apps](https://api.slack.com/apps), create app with:
   - Scopes: `chat:write`, `chat:write.public`
2. Get OAuth token, add in n8n Slack credential

---

## Part 7 — Activate and Test

### Activate the workflow

1. Open the workflow in n8n
2. Toggle the **Inactive** switch to **Active** (top right)
3. Confirm all nodes show green checkmarks (no credential errors)

### Test with curl

```bash
# Hot lead test
bash test-webhook.sh hot

# Warm lead test
bash test-webhook.sh warm

# Cold lead test
bash test-webhook.sh cold
```

### Test with the HTML form

1. Open `lead-form.html` in your browser (double-click or use Live Server)
2. The form posts to `http://localhost:5678/webhook/lead-capture`
3. Fill in the form and submit
4. Check: n8n execution log, Google Sheet, Gmail sent, Slack notification

### Check execution logs

In n8n: **Executions** tab → click on the latest run → see each node's input/output

---

## Common Errors and Fixes

### Error 1: Webhook not receiving data

**Symptom:** curl returns `connection refused` or `404`

**Fixes:**
```bash
# Check n8n is running
docker compose ps

# Check the workflow is ACTIVE (not inactive)
# In n8n UI, check the toggle is ON

# Verify the webhook URL matches
# Should be: http://localhost:5678/webhook/lead-capture
# NOT: http://localhost:5678/webhook-test/lead-capture (that's test mode only)
```

---

### Error 2: Gemini returns 400 or 403

**Symptom:** HTTP Request node fails with `400 Bad Request` or `403 Forbidden`

**Fixes:**
- Check your API key is correct in the credential (no extra spaces)
- Verify the API key has **Generative Language API** enabled in Google Cloud Console
- Test the key directly:
  ```bash
  curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=YOUR_KEY" \
    -H 'Content-Type: application/json' \
    -d '{"contents":[{"parts":[{"text":"Say hello"}]}]}'
  ```
- If using free tier, check quota limits at [aistudio.google.com](https://aistudio.google.com)

---

### Error 3: Google Sheets node fails with permission error

**Symptom:** `The caller does not have permission` or `403`

**Fixes:**
- Re-authenticate: delete the credential in n8n and recreate it
- Make sure the Google Sheet is owned by the same Google account you authorized
- Verify the Spreadsheet ID is correct (just the ID, not the full URL)
- Check that Google Sheets API is enabled in Google Cloud Console

---

### Error 4: Gmail fails to send

**Symptom:** `Invalid grant` or `insufficient permission`

**Fixes:**
- Delete and recreate the Gmail OAuth credential in n8n
- Make sure Gmail API is enabled in Google Cloud Console
- The email in the `sendTo` field must be a valid format: `={{ $json.email }}`
- If getting rate limits: Gmail free accounts have a 500 emails/day limit

---

### Error 5: Gemini JSON parsing fails in Code node

**Symptom:** Code node throws `Failed to parse Gemini JSON`

**Fixes:**
- Gemini sometimes wraps JSON in markdown code blocks. The Code node already strips these, but:
- Lower the temperature: in the HTTP Request body, set `"temperature": 0.0`
- Add this to the prompt: `"IMPORTANT: Return ONLY raw JSON, no markdown, no explanation"`
- In the Code node, add a more aggressive cleaner:
  ```javascript
  const cleanText = rawText
    .replace(/^[^{]*/s, '')  // strip everything before first {
    .replace(/[^}]*$/s, '')  // strip everything after last }
    .trim();
  ```

---

### Error 6: Slack notification not posting

**Symptom:** Slack node fails or channel not found

**Fixes:**
- Make sure the `#leads` channel exists in your Slack workspace
- If using OAuth bot: invite the bot to the channel with `/invite @Lead Bot`
- Verify the credential is connected (not just saved)
- Try changing channel to your own username: `@yourusername`

---

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Runs n8n in Docker |
| `workflow.json` | Import into n8n to create the workflow |
| `lead-form.html` | Beautiful lead capture form |
| `sample-payload.json` | Example webhook body for testing |
| `test-webhook.sh` | curl script to test all 3 lead types |
| `google-sheets-setup.md` | Column setup guide for Google Sheets |
| `.env.example` | Template for environment variables |
| `README.md` | This file |

---

## Loom Video Script (Portfolio Recording)

Record a 5-7 minute video covering these sections for maximum client impact:

### Section 1 — The Problem (30 seconds)
> "Manually qualifying leads takes hours. A sales team shouldn't spend 30% of their time figuring out who's worth calling. This workflow handles that automatically."

**Show:** A messy spreadsheet or email inbox

### Section 2 — The Architecture (60 seconds)
> "Here's the full system — a lead comes in, Gemini AI scores it, it hits Google Sheets, triggers the right email, and alerts the team on Slack. Zero human intervention."

**Show:** The n8n workflow canvas with all nodes visible. Zoom in on the Switch node and explain the Hot/Warm/Cold routing.

### Section 3 — Live Demo (2-3 minutes)
1. Open `lead-form.html` in browser
2. Fill in a **Hot lead** (mention budget, decision-maker, urgency)
3. Submit the form
4. Switch to n8n — show the execution completing in real time
5. Open Google Sheets — show the new row appear
6. Show the Gmail inbox — open the personalized hot lead email
7. Show Slack — the notification with AI score

Repeat with a **Cold lead** to show different email content.

### Section 4 — The Code / Customization (60 seconds)
> "Everything is configurable. The AI prompt, the scoring rules, the email templates — all can be customized per client."

**Show:** The Code node with the Gemini response parser. The Gmail node with the HTML template.

### Section 5 — Business Value (30 seconds)
> "This saves 5-10 hours per week for a sales team. Hot leads get a same-day response automatically. No lead falls through the cracks. This is what I build for clients."

---

## Docker Management Commands

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Restart
docker compose restart n8n

# View logs
docker compose logs -f n8n

# Update n8n to latest
docker compose pull && docker compose up -d

# Backup n8n data
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-backup.tar.gz /data
```

---

## Production Deployment Notes

For deploying to a server (e.g., DigitalOcean, AWS EC2):

1. Set `WEBHOOK_URL=https://yourdomain.com/`
2. Set `N8N_PROTOCOL=https`
3. Set `N8N_BASIC_AUTH_ACTIVE=true` and change the password
4. Use a reverse proxy (Nginx/Caddy) with SSL certificate (Let's Encrypt)
5. Update the HTML form's `WEBHOOK_URL` to your production URL

---

*Built with n8n + Google Gemini AI — Portfolio project for AI Automation services*
