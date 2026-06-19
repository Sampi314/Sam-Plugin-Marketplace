# ============================================================================
# lib/credential-helper.ps1 — OAuth + Credential Manager fallback
# ============================================================================
#
# Extracted from the classic statusline script. In the Extended variant, the
# 5h / weekly usage widgets first check $ctx.rate_limits.* (Claude Code v2.1+
# provides this natively). If absent (older Claude Code), they fall back to
# Get-RateLimitsFallback below, which:
#   1. Retrieves the OAuth token from Windows Credential Manager
#      (via advapi32.dll P/Invoke) or known on-disk credential files
#   2. Calls https://api.anthropic.com/api/oauth/usage with the token
#   3. Caches the result for 15 seconds in $env:TEMP
#
# When the host is on Claude Code v2.1+, none of this code runs.
# ============================================================================

$script:USAGE_CACHE_FILE = Join-Path $env:TEMP 'claude-statusline-usage.json'
$script:USAGE_CACHE_SEC  = 15

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinCred {
    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll")]
    public static extern void CredFree(IntPtr buffer);

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetCredential(string target) {
        IntPtr credPtr;
        if (!CredRead(target, 1, 0, out credPtr)) return null;
        try {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            if (cred.CredentialBlobSize > 0) {
                return Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
            }
            return null;
        } finally {
            CredFree(credPtr);
        }
    }
}
"@ -ErrorAction SilentlyContinue

function Get-OAuthToken {
    foreach ($t in @(
        'Claude Code-credentials',
        'claude-code-credentials',
        'Claude Code',
        'claude-code',
        'Claude',
        'Anthropic Claude Code'
    )) {
        try {
            $raw = [WinCred]::GetCredential($t)
            if ($raw) {
                $p = $raw | ConvertFrom-Json -ErrorAction Stop
                if ($p.claudeAiOauth -and $p.claudeAiOauth.accessToken) { return $p.claudeAiOauth.accessToken }
                if ($p.accessToken) { return $p.accessToken }
            }
        } catch { continue }
    }
    foreach ($fp in @(
        (Join-Path (Join-Path $env:USERPROFILE '.claude') '.credentials.json'),
        (Join-Path (Join-Path $env:USERPROFILE '.claude') 'credentials.json'),
        (Join-Path (Join-Path $env:APPDATA 'Claude Code') 'credentials.json'),
        (Join-Path (Join-Path $env:LOCALAPPDATA 'Claude Code') 'credentials.json'),
        (Join-Path (Join-Path $env:APPDATA 'Anthropic') 'credentials.json')
    )) {
        if (Test-Path $fp) {
            try {
                $p = Get-Content $fp -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($p.claudeAiOauth -and $p.claudeAiOauth.accessToken) { return $p.claudeAiOauth.accessToken }
                if ($p.accessToken) { return $p.accessToken }
            } catch { continue }
        }
    }
    return $null
}

function Get-RateLimitsFallback {
    # Returns @{ five_hour = @{ used_percentage; resets_at }; seven_day = @{ ... } }
    # or @{ five_hour = $null; seven_day = $null } on failure.
    function _ReadCache {
        if (Test-Path $script:USAGE_CACHE_FILE) {
            try { return (Get-Content $script:USAGE_CACHE_FILE -Raw | ConvertFrom-Json -ErrorAction Stop) } catch {}
        }
        return $null
    }

    if (Test-Path $script:USAGE_CACHE_FILE) {
        $age = (Get-Date) - (Get-Item $script:USAGE_CACHE_FILE).LastWriteTime
        if ($age.TotalSeconds -lt $script:USAGE_CACHE_SEC) {
            $cached = _ReadCache
            if ($cached) { return $cached }
        }
    }

    $token = Get-OAuthToken
    if (-not $token) {
        if (Test-Path $script:USAGE_CACHE_FILE) {
            $staleAge = (Get-Date) - (Get-Item $script:USAGE_CACHE_FILE).LastWriteTime
            if ($staleAge.TotalMinutes -lt 30) {
                $stale = _ReadCache
                if ($stale) { return $stale }
            }
        }
        return @{ five_hour = $null; seven_day = $null }
    }

    try {
        $headers = @{
            'Accept'         = 'application/json'
            'Content-Type'   = 'application/json'
            'Authorization'  = "Bearer $token"
            'anthropic-beta' = 'oauth-2025-04-20'
            'User-Agent'     = 'claude-code/2.1.0'
        }
        $resp = Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' `
                    -Method GET -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        $result = @{ five_hour = $null; seven_day = $null }
        if ($null -ne $resp.five_hour) {
            $result.five_hour = @{
                used_percentage = [double]$resp.five_hour.utilization
                resets_at       = if ($resp.five_hour.resets_at) { $resp.five_hour.resets_at } else { $null }
            }
        }
        if ($null -ne $resp.seven_day) {
            $result.seven_day = @{
                used_percentage = [double]$resp.seven_day.utilization
                resets_at       = if ($resp.seven_day.resets_at) { $resp.seven_day.resets_at } else { $null }
            }
        }
        $result | ConvertTo-Json -Depth 4 -Compress |
            Set-Content $script:USAGE_CACHE_FILE -Encoding UTF8 -ErrorAction SilentlyContinue
        return $result
    } catch {
        $stale = _ReadCache
        if ($stale) { return $stale }
        return @{ five_hour = $null; seven_day = $null }
    }
}

function Get-RateLimits($ctx) {
    # Primary entry point used by rate-limit widgets.
    # Returns the same shape regardless of whether built-in or fallback path is used.
    if ($ctx -and $ctx.rate_limits) {
        $five = $null; $seven = $null
        if ($ctx.rate_limits.five_hour -and $null -ne $ctx.rate_limits.five_hour.used_percentage) {
            $five = @{
                used_percentage = [double]$ctx.rate_limits.five_hour.used_percentage
                resets_at       = $ctx.rate_limits.five_hour.resets_at
            }
        }
        if ($ctx.rate_limits.seven_day -and $null -ne $ctx.rate_limits.seven_day.used_percentage) {
            $seven = @{
                used_percentage = [double]$ctx.rate_limits.seven_day.used_percentage
                resets_at       = $ctx.rate_limits.seven_day.resets_at
            }
        }
        if ($five -or $seven) {
            return @{ five_hour = $five; seven_day = $seven; source = 'builtin' }
        }
    }
    # Fall back to OAuth API
    $r = Get-RateLimitsFallback
    $r['source'] = 'oauth-fallback'
    return $r
}
