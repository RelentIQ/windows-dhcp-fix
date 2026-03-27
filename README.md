# Windows DHCP Fix — KB5077181 / KB5079473 Workaround

> **Automated fix for the Windows 10 and 11 networking bug introduced by the February and March 2026 Patch Tuesday updates, which breaks DHCP and leaves machines connected but with no internet.**

---

## The Problem

Microsoft's February 2026 cumulative update **KB5077181** introduced a bug in the Windows networking stack affecting Windows 10 and Windows 11 machines. The bug carried over into the March 2026 update **KB5079473** (build 26200.8037) and remains unresolved.

After the update installs, Windows fails to complete DHCP negotiation — meaning it connects to the router but never receives a gateway address. The result is a machine that shows as "Connected" but has no internet access.

**Confirmed symptoms:**
- Wi-Fi or Ethernet shows "Connected" but no internet
- `ipconfig` shows no Default Gateway, or a 169.x.x.x (APIPA) address
- Browser shows "No internet" or DNS errors
- Restarting the router or adapter makes no difference
- Running Linux on the same hardware connects without issue — confirming this is a Windows software bug, not a hardware or ISP problem

**Affected updates:**
- KB5077181 — Windows 11 24H2 / 25H2 (February 10, 2026)
- KB5079473 — Windows 11 24H2 / 25H2 (March 10, 2026, build 26200.8037)
- KB5075912 — Windows 10 22H2 (February 10, 2026)

---

## Who This Is For

- **Non-technical users** who just want their internet back — the scripts handle everything automatically
- **IT technicians** needing a reliable, scriptable fix to deploy across multiple affected machines
- **Businesses** whose staff cannot work due to no internet on company laptops

---

## What's Included

| File | Purpose |
|------|---------|
| `fix_dhcp.bat` | Detects your gateway and assigns a static IP to restore internet access |
| `restore_dhcp.bat` | Reverts your adapter back to automatic DHCP once Microsoft releases an official fix |

---

## How to Use

### Step 1 — Restore internet now (`fix_dhcp.bat`)

1. Download `fix_dhcp.bat` to the affected Windows PC (use a USB drive if needed)
2. **Right-click** the file → **"Run as administrator"**
3. The script automatically detects your router and network adapter
4. Review the configuration shown on screen, then press **Enter** to apply
5. Internet should be restored within a few seconds

> If the script cannot detect your gateway automatically, it will scan 21 common router addresses. If none respond, it will ask you to enter your router IP manually — usually printed on the label on the bottom of your router.

### Step 2 — Restore automatic IP later (`restore_dhcp.bat`)

Once Microsoft releases an official fix and your Windows is updated, run this to switch back to automatic IP assignment.

1. **Right-click** `restore_dhcp.bat` → **"Run as administrator"**
2. Press **Enter** to confirm
3. Done — your adapter will revert to automatic DHCP

> **Important:** While the static IP workaround is active, your IP address is fixed. This is fine for home use but may cause conflicts on managed business networks. Run the restore script as soon as Microsoft patches the issue.

---

## How the Scripts Work (Technical Detail)

### `fix_dhcp.bat`

1. **Checks for administrator rights** — exits with a clear error if not elevated
2. **Detects the gateway** using three methods in order:
   - Parses the Windows routing table (`route print`)
   - If no route found, pings 21 common router addresses (covers BT, Sky, Virgin Media, Huawei, TP-Link, Fritz!Box, and more)
   - If none respond, prompts the user for manual input with basic validation
3. **Identifies the active network adapter** using four fallback methods:
   - Matches the adapter to the detected gateway via `netsh interface ip show config`
   - Scans `netsh interface show interface` for connected adapters
   - Queries WMI for adapters with a gateway assigned
   - Queries WMI for any enabled adapter with a connection ID
4. **Calculates a safe static IP** — takes the gateway's network prefix and appends `.200` (e.g. `192.168.1.1` → `192.168.1.200`)
5. **Applies the config** via `netsh` with the static IP, detected subnet mask, gateway, and DNS (`8.8.8.8` / `1.1.1.1`)
6. **Verifies** by pinging `8.8.8.8` and reports success, partial success, or failure

### `restore_dhcp.bat`

1. **Checks for administrator rights**
2. **Detects the active adapter** using the same four-method fallback logic
3. **Reverts to DHCP** via `netsh interface ip set address dhcp` and `netsh interface ip set dns dhcp`
4. **Verifies** internet connectivity is restored

---

## Requirements

- Windows 10 or Windows 11
- Administrator account
- No additional software — uses built-in Windows `netsh` and `route` commands
- Works over Wi-Fi or Ethernet

---

## Tested On

- Windows 11 24H2 (Dell laptop) — fix and restore both confirmed working
- Windows 10 22H2 — fix confirmed working

---

## Disclaimer

This is a **temporary workaround**, not an official Microsoft fix. The scripts assign a static IP to bypass the broken DHCP client in affected Windows builds. They do not modify the registry, remove updates, or make any permanent system changes beyond the network adapter IP configuration.

Always verify the contents of scripts before running them. Run at your own risk.

---

## License

MIT — free to use, share, and modify. See [LICENSE](LICENSE) for details.

---

## Credit

Built and tested by **Nikolay** at **Revive My Device** — IT repair specialists based in London.

📞 **020 8050 9779**

*If this helped you, a star on the repo goes a long way. Feel free to share with anyone dealing with the same issue.*
