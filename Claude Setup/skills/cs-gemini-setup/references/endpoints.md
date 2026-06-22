# Gemini endpoints — what works where

A short reference so the next time something fails, the fix is obvious.

## The endpoint base URLs

| Base URL | Status | Use it for |
|---|---|---|
| `https://generativelanguage.googleapis.com/v1/` | **Stable** | Everything. This is what `setup.ps1`, `verify.ps1`, `troubleshoot.ps1`, and `generate_image_gemini.py` all hit. |
| `https://generativelanguage.googleapis.com/v1beta/` | Preview | Text models only. Image generation here returns `limit: 0` on the free tier. |

If a script uses the Google `google-genai` Python SDK with default options, it goes to **v1beta**. That is the silent foot-gun behind the AI-blog image script being rewritten in raw `urllib` against `/v1/`. See [[feedback_gemini_image_endpoint]].

## Model IDs (as of 2026-06)

| Model ID | Surface | Pricing | Notes |
|---|---|---|---|
| `gemini-2.5-flash` | text | free tier available, paid for sustained use | The cheapest fast model; perfect for the verifier's text check. |
| `gemini-2.5-pro` | text | paid | Slower, higher reasoning ceiling. Not needed for setup verification. |
| `gemini-2.5-flash-image` | image | paid only | The image generation model used by the daily AI blog. **Image generation has zero free-tier headroom** — if billing is not enabled on the underlying Cloud project, every call returns HTTP 429. |

## Request shape (POST, JSON)

```text
POST https://generativelanguage.googleapis.com/v1/models/<model-id>:generateContent
Headers:
  Content-Type: application/json
  x-goog-api-key: AIza...
Body:
  {"contents": [ {"parts": [ {"text": "..."} ] } ] }
```

For image generation, the response body contains parts with `inlineData.data` (base64-encoded PNG/JPEG bytes). Empty `inlineData` with a 200 response means the model answered in text and did not actually generate an image — usually a prompt clarity issue, not an auth one.

## HTTP status decoder

| Status | Meaning | Where to fix |
|---|---|---|
| **200** | Success. | Nothing to do. |
| **400** | Malformed body — likely a script bug, not a setup issue. | Open the script and check the JSON it sends. |
| **401** | Key invalid, expired, or revoked. | Re-issue at `https://aistudio.google.com/apikey`; rerun `setup.ps1`. |
| **403** | Key authenticates but the call is refused. | Either the Generative Language API is disabled on the Cloud project, or the key has referrer / IP restrictions in AI Studio. |
| **429** | Quota or credits exhausted. | If body mentions "credits", top up at `https://aistudio.google.com/`. If body mentions "quota", upgrade to paid tier. |
| **5xx** | Transient Google-side error. | Wait and retry. Persistent 5xx warrants checking https://status.cloud.google.com. |

## Billing escape hatch

The free tier covers text models for low-volume use. **It does not cover image generation.** If `verify.ps1` reports text OK but image FAILED with 429, the project needs billing turned on.

To enable billing:

1. Open `https://aistudio.google.com/` and find the project the key belongs to.
2. Click **Set up billing** and link a Google Cloud billing account.
3. Once the AI Studio project shows "Paid tier", retry `verify.ps1`.

After enabling billing, expect a one-off delay (usually seconds, occasionally minutes) before image generation calls succeed.

## Why this skill avoids the SDK

The Python `google-genai` SDK is convenient but adds two [2] hidden behaviours that have caused real grief on this machine:

- **Defaults to `/v1beta/`** for the image model, where image generation is hard-capped at zero on every plan.
- **Requires a Python install matched to the SDK version**, plus `pip install google-genai`, plus a sentinel cache directory.

Both `verify.ps1` and `troubleshoot.ps1` hit the REST API directly with `Invoke-WebRequest` so the exact bytes on the wire match what `generate_image_gemini.py` sends. If verification passes here, the image script will work too — no untested abstraction in between.
