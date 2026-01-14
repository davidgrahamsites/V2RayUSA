# V2RayUSA - V2Ray VPN Client for macOS

A native macOS menubar application for V2Ray VPN with support for USA servers and VPN tunnel chaining. Built specifically for Apple Silicon (M1/M2/M3) Macs.

## Features

- 🎯 **Native macOS App**: SwiftUI-based menubar application
- 🔒 **Multiple Protocols**: VMess, VLESS, Trojan, Shadowsocks support
- 🌐 **USA Server Optimized**: Pre-configured for quick USA server setup
- 🔗 **VPN Chaining**: Route V2Ray through Astrill or other VPNs
- ⚡ **Apple Silicon Native**: Optimized for M1/M2/M3 Macs (arm64)
- 📦 **Self-Contained**: No external dependencies required
- 🎨 **Clean UI**: Simple menubar interface with easy configuration

## Requirements

- **macOS**: 12.0 (Monterey) or later
- **Hardware**: Apple Silicon Mac (M1, M2, or M3)
- **V2Ray Server**: VMess/VLESS server credentials

## Installation

1. Download `V2RayUSA.dmg` from the releases page
2. Open the DMG file
3. Drag `V2RayUSA.app` to your Applications folder
4. Right-click the app and select "Open" (first launch only - bypasses Gatekeeper)
5. The VPN icon will appear in your menubar

## Configuration

### First-Time Setup

1. Click the V2Ray icon in the menubar
2. Select **Preferences**
3. Enter your server details:
   - **Server Address**: Your V2Ray server hostname or IP
   - **Port**: Usually 443 for TLS connections
   - **User ID**: Your V2Ray UUID (get from server provider)
   - **Protocol**: VMess (most common) or VLESS
   - **Network Type**: WebSocket (recommended) or TCP
   - **Enable TLS**: Check this for secure connections
4. Click **Save Configuration**

### Quick Start Example

```
Server Name: USA Main Server
Server Address: us-server.example.com
Port: 443
Protocol: VMess
User ID: 12345678-1234-1234-1234-123456789abc
Encryption: auto
Network: WebSocket
Path: /
Enable TLS: ✓
```

## Usage

### Connecting

1. Click the menubar icon (lock shield)
2. Click **Connect**
3. Icon changes to filled shield when connected
4. Local SOCKS5 proxy runs on `127.0.0.1:1080`

### Disconnecting

1. Click the menubar icon
2. Click **Disconnect**

### VPN Tunnel Chaining (Astrill)

For routing V2Ray through Astrill:

1. **Connect to Astrill VPN first**
2. Wait for Astrill connection to establish
3. **Then connect V2RayUSA**
4. Traffic flow: `Your Mac → Astrill → V2Ray → Internet`

This provides additional security and can help bypass certain restrictions.

### Viewing Logs

1. Open Preferences
2. Click **View Logs**
3. Logs are saved to `~/Library/Logs/V2RayUSA/v2ray.log`

## Building from Source

See [BUILD.md](BUILD.md) for complete build instructions.

Quick build:

```bash
cd V2RayUSA
chmod +x build-scripts/build.sh
./build-scripts/build.sh
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

### Common Issues

**App won't open - "unidentified developer"**
- Right-click the app → Open (don't double-click)
- Go to System Preferences → Privacy & Security → Allow anyway

**Connection fails**
- Check server credentials are correct
- Verify server is online
- Check logs: Preferences → View Logs

**No internet after connecting**
- Configure system proxy to use SOCKS5 `127.0.0.1:1080`
- Or use a browser extension like SwitchyOmega

## Technical Details

- **Local Proxy**: SOCKS5 on `127.0.0.1:1080`
- **V2Ray Version**: 5.20.0
- **Swift Version**: 5.0
- **Minimum macOS**: 12.0 (Monterey)
- **Architecture**: arm64 (Apple Silicon only)

## Security & Privacy

- Server credentials stored in macOS Keychain
- No telemetry or analytics
- All traffic encrypted with TLS (when enabled)
- App runs with minimal permissions

## License

MIT License - See LICENSE file for details

## Support

For issues and feature requests:
- GitHub Issues: https://github.com/yourusername/v2rayusa
- Documentation: See BUILD.md and TROUBLESHOOTING.md

## Credits

Built with:
- [V2Ray Core](https://github.com/v2fly/v2ray-core) - V2Ray protocol implementation
- SwiftUI - Native macOS UI framework

---

**Note**: This app is for educational and privacy purposes. Use responsibly and comply with local laws.
