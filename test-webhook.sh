#!/bin/bash

# ============================================================
# AI Lead Automation System — Webhook Test Script
# ============================================================
# Usage: bash test-webhook.sh [hot|warm|cold]
# Default test is a HOT lead
# ============================================================

WEBHOOK_URL="http://localhost:5678/webhook/lead-capture"

# ---- HOT lead (Score 8-10) ----
HOT_PAYLOAD='{
  "name": "Sarah Johnson",
  "email": "sarah.johnson@techinnovate.io",
  "company": "TechInnovate Solutions",
  "message": "Hi, we are a 50-person SaaS company looking to automate our lead qualification process. We have a clear budget of $5,000/month and need to make a decision by end of quarter. I am the CTO and the decision maker on this. Can we schedule a call this week?"
}'

# ---- WARM lead (Score 5-7) ----
WARM_PAYLOAD='{
  "name": "Mark Chen",
  "email": "mark.chen@digitalagency.com",
  "company": "Digital Agency Co",
  "message": "Hello, I heard about your AI automation services and I am interested in learning more. We currently handle leads manually and it takes a lot of time. Not sure about budget yet but would love to see a demo sometime."
}'

# ---- COLD lead (Score 1-4) ----
COLD_PAYLOAD='{
  "name": "Alex Student",
  "email": "alex@gmail.com",
  "company": "University Project",
  "message": "Hi, I am a student learning about AI automation for a class project. Just curious how this works. No budget but want to understand the tech."
}'

# Select payload based on argument
LEAD_TYPE=${1:-hot}

case "$LEAD_TYPE" in
  hot)
    PAYLOAD="$HOT_PAYLOAD"
    echo "🔥 Sending HOT lead test..."
    ;;
  warm)
    PAYLOAD="$WARM_PAYLOAD"
    echo "🌡️  Sending WARM lead test..."
    ;;
  cold)
    PAYLOAD="$COLD_PAYLOAD"
    echo "❄️  Sending COLD lead test..."
    ;;
  *)
    echo "Usage: bash test-webhook.sh [hot|warm|cold]"
    exit 1
    ;;
esac

echo ""
echo "Webhook URL: $WEBHOOK_URL"
echo "Payload:"
echo "$PAYLOAD" | python3 -m json.tool 2>/dev/null || echo "$PAYLOAD"
echo ""
echo "Response:"
echo "------------------------------------------------------------"

curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" | python3 -m json.tool 2>/dev/null || \
curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

echo ""
echo "------------------------------------------------------------"
echo "Done. Check n8n execution log at http://localhost:5678"
