# RegimeTracker

A Final Fantasy XI addon for Windower that tracks regime progress by monitoring mob deaths and checking mob families against regime requirements.

## Features

- **Fully Automatic**: No manual setup required - automatically detects and tracks regimes from chat messages
- **Smart Detection**: Uses the last killed mob and chat messages to determine regime family and progress
- **Progress Persistence**: Saves regime progress between sessions
- **Real-time Updates**: Shows current regime status and progress automatically
- **Simple Commands**: Minimal command interface for status and control

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
- `//regime clear` - Clear current regime
- `//regime toggle` - Enable/disable tracking
- `//regime reload` - Reload the addon
- `//regime unload` - Unload the addon

### How It Works

The addon automatically detects regimes when you:

1. **Kill a mob** - The addon tracks the last mob you killed
2. **See progress message** - When the game shows "You defeated a designated target. (Progress: X/Y)"
3. **Auto-detection** - The addon automatically determines the regime family and starts tracking

**No manual setup required!**

### Example Workflow

1. **Kill a mob** - Any mob in the game
2. **See progress message** - Game shows "You defeated a designated target. (Progress: 2/4)"
3. **Auto-tracking starts** - Addon automatically detects regime family and progress
4. **Monitor status** - Use `//regime status` to see current progress
5. **Completion** - When target is reached: "Regime complete! You have defeated 4 [Family] targets."

### Auto-Detection Features

- **Chat Message Parsing**: Monitors chat for progress updates and completion messages
- **Mob Family Detection**: Uses the last killed mob to determine regime family
- **Progress Synchronization**: Keeps regime progress in sync with game messages
- **Grounds Tome Selection**: Automatically detects when you select a new regime

## Configuration

The addon automatically saves settings to a config file. Key settings include:

- `enabled`: Enable/disable tracking
- `auto_track`: Automatic regime tracking
- `show_progress`: Show progress messages
- `chat_mode`: Chat output mode (echo, say, party, etc.)

## How It Works

1. **Mob Death Detection**: Monitors incoming game packets to detect when mobs are killed
2. **Chat Message Monitoring**: Listens for regime progress messages in chat for automatic updates
3. **Family Lookup**: Queries the InfoBar database to get the family of the last killed mob
4. **Progress Tracking**: Automatically updates progress based on chat messages
5. **Status Updates**: Progress messages are displayed and saved
6. **Auto-Detection**: Can automatically detect new regimes when selected from grounds tomes

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
