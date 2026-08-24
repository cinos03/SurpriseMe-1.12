# Surprise Me! - Auto-Invite Addon for TurtleWoW

[![Version](https://img.shields.io/badge/version-1.1-blue.svg)](https://github.com/yourusername/SurpriseMe)
[![WoW Version](https://img.shields.io/badge/WoW-1.12-orange.svg)](https://turtle-wow.org/)

**Surprise Me!** is a World of Warcraft 1.12 addon designed for TurtleWoW that automatically invites players to your group when they whisper specific keywords. Perfect for raid leaders, dungeon groups, or anyone who frequently forms groups!

## 🌟 Features

- **Automatic Invitations**: Instantly invite players who whisper configurable keywords
- **Keyword Management**: Add, remove, and customize trigger words
- **Whisper Responses**: Optionally send automatic responses when inviting players
- **Smart Group Management**: Converts a party to a raid only when inviting a 6th player (a full 5-man dungeon group stays a party)
- **User-Friendly GUI**: Easy-to-use configuration interface
- **Slash Commands**: Full command-line interface for power users
- **Duplicate Prevention**: Won't invite players already in your group
- **TurtleWoW Optimized**: Built specifically for the TurtleWoW 1.12 client

## 📦 Installation

1. Download the `SurpriseMe` folder
2. Extract it to your `Interface\AddOns\` directory
3. The path should look like: `Interface\AddOns\SurpriseMe\`
4. Restart World of Warcraft or reload your UI (`/reload`)

## 🚀 Quick Start

1. **Load the addon** - You'll see a message in chat when it's loaded
2. **Open settings** - Type `/surpriseme` or `/sm` to open the configuration GUI
3. **Enable the addon** - Check the "Enable Surprise Me!" checkbox
4. **Configure keywords** - The addon comes with default keywords: "invite", "inv", "raid"
5. **Start inviting** - Players who whisper any of your keywords will be automatically invited!

## ⚙️ Configuration

### GUI Configuration
Open the configuration window with `/surpriseme` to access:

- **Enable/Disable Toggle**: Turn the addon on or off
- **Whisper Response**: Toggle automatic response messages
- **Response Message**: Customize the message sent to invited players
- **Keyword Management**: Add or remove trigger words
- **Live Keyword List**: View and manage all active keywords

### Default Keywords
The addon comes pre-configured with these keywords:
- `invite`
- `inv` 
- `raid`

### Default Response Message
> "You have been invited to the group!"

## 💬 Slash Commands

| Command | Description |
|---------|-------------|
| `/surpriseme` or `/sm` | Open configuration GUI |
| `/surpriseme toggle` | Enable/disable auto invite |
| `/surpriseme add <keyword>` | Add a new keyword |
| `/surpriseme remove <keyword>` | Remove a keyword |
| `/surpriseme list` | List all active keywords |
| `/surpriseme help` | Show available commands |

### Examples
```
/sm add lfg                    # Add "lfg" as a trigger keyword
/sm remove inv                 # Remove "inv" keyword
/sm toggle                     # Toggle addon on/off
/surpriseme add "looking for group"  # Add multi-word phrase
```

## 🛡️ Smart Features

### Automatic Raid Conversion
A 5-player party is left as a party (so Dungeon Finder groups keep working). The addon converts to a raid only when you invite a 6th player via a keyword whisper, and only if you are the party leader and Dungeon Finder / meeting-stone queue is not active.

### Duplicate Protection
The addon checks if a player is already in your group before sending an invitation, preventing spam and errors.

### Case-Insensitive Matching
Keywords work regardless of capitalization - "INVITE", "invite", and "InViTe" all work the same.

### Keyword Flexibility
Add any keywords you want:
- Single words: `inv`, `raid`, `dungeon`
- Abbreviations: `lfg`, `lfm`, `lf1m`
- Phrases: `looking for group`, `need invite`

## 🔧 Technical Details

- **Compatible with**: World of Warcraft 1.12 (TurtleWoW)
- **Saved Variables**: Configuration persists between sessions
- **Memory Usage**: Lightweight and efficient
- **Event-Driven**: Only processes whispers when addon is enabled

## 📋 Use Cases

### For Raid Leaders
- Set keywords like "raid", "mc", "bwl", "aq40"
- Enable whisper responses to acknowledge invitations
- Let the addon handle invites while you focus on organization

### For Dungeon Groups
- Use keywords like "sm", "scholo", "strat", "dm"
- Quickly fill groups without manual invitation management

### For Social Groups
- Keywords like "guild run", "social", "chill"
- Build communities with automatic group formation

## ⚠️ Important Notes

- **Leader/Assistant Required**: You must be group leader or have assist to invite players
- **Whisper Only**: The addon only responds to whispers, not guild/party/raid chat
- **Manual Override**: You can still invite players manually - the addon doesn't interfere
- **Privacy**: The addon only processes whispers, it doesn't read other chat channels

## 🐛 Troubleshooting

### Common Issues

**Addon not working?**
- Make sure it's enabled: `/surpriseme toggle`
- Check if you're group leader or have assist
- Verify the addon loaded: Look for the load message in chat

**Keywords not triggering?**
- Check keyword list: `/surpriseme list`
- Ensure keywords are added correctly
- Try `/reload` to refresh the addon

**GUI not opening?**
- Type `/surpriseme` or `/sm`
- Wait a moment after login for addon to fully load
- Try `/reload` if the issue persists

### Debug Mode
For troubleshooting, you can enable debug mode by editing the saved variables:
```lua
SurpriseMeDB.debugMode = true
```

## 🤝 Contributing

Found a bug or have a feature request? 

1. Check existing issues first
2. Create a detailed bug report or feature request
3. Include your WoW version and addon version
4. Provide steps to reproduce any issues

## 📄 License

This addon is provided as-is for the TurtleWoW community. Feel free to modify and redistribute while keeping credit to the original author.

## 🙏 Credits

- Built for the amazing TurtleWoW community
- Inspired by classic raid leading challenges
- Thanks to all beta testers and contributors

---

**Happy Raiding!** 🐢⚔️

*For support, updates, and community discussion, visit the TurtleWoW forums or discord.*
