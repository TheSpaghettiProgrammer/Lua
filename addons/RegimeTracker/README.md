# RegimeTracker

A Final Fantasy XI addon for Windower that tracks regime progress by monitoring mob deaths and checking mob families against regime requirements.

## Features

- **Automatic Tracking**: Monitors mob deaths and automatically tracks progress for designated regime targets
- **Family-based Detection**: Uses the InfoBar database to identify mob families and match them to regime requirements
- **Progress Persistence**: Saves regime progress between sessions
- **Flexible Messaging**: Configurable chat output modes (echo, say, party, linkshell, etc.)
- **Easy Commands**: Simple command interface for managing regimes

## Requirements

- Windower 4+ with Lua support
- InfoBar addon (for mob family database access)
- Final Fantasy XI

## Installation

1. Download the RegimeTracker folder
2. Place it in your Windower addons directory
3. Load the addon with: `//lua load RegimeTracker`

## Usage

### Basic Commands

- `//regime help` - Show help information
- `//regime status` - Show current regime status
- `//regime set <family> <total>` - Set a new regime
- `//regime clear` - Clear current regime
- `//regime toggle` - Enable/disable tracking
- `//regime reload` - Reload the addon
- `//regime unload` - Unload the addon

### Setting Up a Regime

To start tracking a regime, use the set command with the mob family and total count:

```
//regime set "Goblin" 4
```

This will start tracking Goblin kills with a target of 4 total.

### Example Workflow

1. **Set Regime**: `//regime set "Goblin" 4`
2. **Kill Mobs**: The addon automatically tracks kills of the specified family
3. **Monitor Progress**: Progress messages appear after each kill: "You defeated a designated target. (Progress: 2/4)"
4. **Completion**: When the target is reached: "Regime complete! You have defeated 4 Goblin targets."

## Configuration

The addon automatically saves settings to a config file. Key settings include:

- `enabled`: Enable/disable tracking
- `auto_track`: Automatic regime tracking
- `show_progress`: Show progress messages
- `chat_mode`: Chat output mode (echo, say, party, etc.)

## How It Works

1. **Mob Death Detection**: Monitors incoming game packets to detect when mobs are killed
2. **Family Lookup**: Queries the InfoBar database to get the family of the killed mob
3. **Progress Tracking**: If the mob family matches the current regime, progress is incremented
4. **Status Updates**: Progress messages are displayed and saved

## Database Integration

RegimeTracker uses the InfoBar addon's SQLite database to identify mob families. This database contains comprehensive information about monsters including:

- Mob names
- Family classifications
- Zone information
- Level ranges
- Aggression settings

## Troubleshooting

### Addon Not Loading
- Ensure Windower is properly installed and running
- Check that all required dependencies are available

### No Progress Tracking
- Verify the InfoBar addon is installed and has a valid database
- Check that the regime is properly set with `//regime status`
- Ensure the addon is enabled with `//regime toggle`

### Database Connection Issues
- The addon will show a warning if the InfoBar database is not found
- Ensure the InfoBar addon is installed in the correct location

## Support

For issues or questions:
1. Check the help command: `//regime help`
2. Verify your setup and configuration
3. Check Windower forums for similar issues

## License

This addon is provided as-is with no warranty. See the header in the main Lua file for full license details.

## Version History

- **1.0.0**: Initial release with basic regime tracking functionality
