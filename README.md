# Windows DHCP Fix — KB5077181 Workaround

> **A temporary workaround for the February 2026 Windows update that breaks automatic IP/DHCP on some machines, causing loss of gateway and internet connectivity even though the network adapter shows as "Connected".**

---

## The Problem

Microsoft's February 2026 cumulative update **KB5077181** introduced a bug affecting a subset of Windows 10 and Windows 11 machines. After the update is installed, the network adapter fails to obtain an IP address automatically via DHCP — meaning Windows reports you are connected to your router or network, but you have no gateway and therefore no internet access.

Symptoms include:
- Wi-Fi or Ethernet shows "Connected" but no internet
- `ipconfig` shows a 169.x.x.x (APIPA) address or no gateway
- Browser shows "No internet" or DNS errors
- Restarting the router and adapter makes no difference

This is **not** a hardware fault, ISP issue, or router problem — it is a confirmed software regression introduced by KB5077181.

---

## Who This Is For

- **Non-technical users** who just want their internet working again — the scripts are designed to run with a single double-click
- **IT technicians** who need a reliable, automated fix to deploy across multiple affected machines without manual configuration on each one

---

## What's Included

| File | Purpose |
|------|---------|
| `fix_dhcp.bat` | Detects your gateway and applies a static IP as a workaround to restore internet access |
| `restore_dhcp.bat` | Reverts your adapter back to automatic DHCP once Microsoft releases an official patch |

---

## How to Use

### Step 1 — Apply the Fix (`fix_dhcp.bat`)

Use this script to restore internet connectivity right now.

1. Download or copy `fix_dhcp.bat` to the affected Windows PC
2. **Right-click** the file and select **"Run as administrator"**
3. The script will automatically detect your router/gateway
4. Review the configuration shown on screen, then press **Enter** to apply
5. Your internet connection should be restored within a few seconds

> If the script cannot detect your gateway automatically, it will prompt you to enter your router's IP address manually (usually printed on the bottom of the router).

### Step 2 — Restore DHCP Later (`restore_dhcp.bat`)

Once Microsoft releases an official fix for KB5077181 and your Windows updates are current, run this script to switch back to automatic IP assignment.

1. **Right-click** `restore_dhcp.bat` and select **"Run as administrator"**
2. Press **Enter** when prompted to confirm
3. Your adapter will revert to automatic DHCP within a few seconds

> **Note:** Once Microsoft releases an official fix, run `restore_dhcp.bat` to return to automatic DHCP. Keeping a static IP long-term is unnecessary and may cause conflicts on some networks.

---

## What the Scripts Do (Technical Detail)

### `fix_dhcp.bat`

1. **Verifies administrator rights** — exits if not elevated
2. **Detects the gateway** using three methods in sequence:
   - Parses the Windows routing table (`route print`)
   - Pings a list of 20+ common router addresses if no route is found
   - Falls back to prompting the user for manual entry
3. **Identifies the active network adapter** using four fallback methods (`netsh ip show config`, `netsh interface show interface`, WMI with gateway filter, WMI with any enabled NIC)
4. **Calculates a safe static IP** by taking the gateway's network prefix and appending `.200` (e.g. gateway `192.168.1.1` → static IP `192.168.1.200`)
5. **Applies the configuration** via `netsh interface ip set address` with the static IP, detected subnet mask, gateway, and Google/Cloudflare DNS (`8.8.8.8` / `1.1.1.1`)
6. **Verifies connectivity** by pinging `8.8.8.8` and reports success or partial success

### `restore_dhcp.bat`

1. **Verifies administrator rights**
2. **Re-identifies the active adapter** using the same multi-method detection
3. **Reverts to DHCP** via `netsh interface ip set address ... dhcp` and `netsh interface ip set dns ... dhcp`
4. **Verifies** that internet connectivity is restored

---

## Requirements

- Windows 10 or Windows 11
- Administrator account (or access to "Run as administrator")
- No additional software required — uses built-in Windows `netsh` and `route` commands

---

## Important Disclaimer

> This is a **temporary workaround** and not an official Microsoft fix. It addresses the symptom (no internet) by switching to a manually assigned static IP until Microsoft resolves the underlying DHCP regression in KB5077181. The scripts do not modify the Windows registry, remove updates, or make any permanent system changes beyond the network adapter's IP configuration. Always run scripts from trusted sources and verify the contents before executing.

---

## Credit

Scripts created and tested by **Revive My Device** — IT support specialists.
📞 Phone: **020 8050 9779**

---

*If this helped you, feel free to share the repo link with others experiencing the same issue.*
