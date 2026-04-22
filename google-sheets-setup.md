# Google Sheets Setup Guide

## Step 1 — Create a New Google Sheet

1. Go to [sheets.google.com](https://sheets.google.com)
2. Click **+ Blank** to create a new spreadsheet
3. Name it: `AI Lead Automation — Leads Database`

---

## Step 2 — Add Column Headers (Row 1)

Copy and paste these headers exactly into **Row 1**, one per column:

| A | B | C | D | E | F | G | H | I | J | K |
|---|---|---|---|---|---|---|---|---|---|---|
| Timestamp | Name | Email | Company | Message | Lead Score | Lead Quality | AI Reason | Reply Tone | Email Sent | Slack Notified |

**Exact headers to type (copy one by one):**

- **A1:** `Timestamp`
- **B1:** `Name`
- **C1:** `Email`
- **D1:** `Company`
- **E1:** `Message`
- **F1:** `Lead Score`
- **G1:** `Lead Quality`
- **H1:** `AI Reason`
- **I1:** `Reply Tone`
- **J1:** `Email Sent`
- **K1:** `Slack Notified`

---

## Step 3 — Format the Sheet

### Make headers bold and colored:
1. Select Row 1 (click the row number `1`)
2. Press **Ctrl+B** (Bold)
3. Fill color → choose a dark blue or green
4. Font color → White

### Freeze the header row:
1. Click **View** → **Freeze** → **1 row**

### Column widths (approximate):
- Timestamp: 180px
- Name: 150px
- Email: 200px
- Company: 180px
- Message: 300px
- Lead Score: 100px
- Lead Quality: 120px
- AI Reason: 300px
- Reply Tone: 120px
- Email Sent: 110px
- Slack Notified: 130px

---

## Step 4 — Get the Spreadsheet ID

Your spreadsheet URL looks like:
```
https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms/edit
```

The **Spreadsheet ID** is the long string between `/d/` and `/edit`:
```
1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms
```

Copy this ID — you will need it when configuring the Google Sheets node in n8n.

---

## Step 5 — Share with n8n Service Account (if using Service Account auth)

If you use **Service Account** authentication instead of OAuth:
1. In n8n, create a Google API Service Account credential
2. Copy the service account email (looks like `name@project.iam.gserviceaccount.com`)
3. In your Google Sheet: **Share** → paste the service account email → **Editor** access

---

## Example Data (what a completed row looks like)

| Timestamp | Name | Email | Company | Message | Lead Score | Lead Quality | AI Reason | Reply Tone | Email Sent | Slack Notified |
|-----------|------|-------|---------|---------|-----------|-------------|-----------|-----------|-----------|----------------|
| 2026-04-17T10:30:00Z | Sarah Johnson | sarah@tech.io | TechInnovate | We have budget and need a decision... | 9 | Hot | Clear budget, decision maker, urgent timeline | urgent | Yes | Yes |
| 2026-04-17T11:15:00Z | Mark Chen | mark@agency.com | Digital Agency | Interested but not sure about budget | 6 | Warm | Interested but vague, needs nurturing | normal | Yes | Yes |
| 2026-04-17T12:00:00Z | Alex Student | alex@gmail.com | University | Student project, no budget | 2 | Cold | No budget, academic interest only | low_priority | Yes | Yes |

---

## Notes

- The n8n Google Sheets node will **append** a new row for each lead automatically
- Make sure the sheet name in n8n matches exactly (default is `Sheet1`)
- Do not delete or rename column headers after setup
