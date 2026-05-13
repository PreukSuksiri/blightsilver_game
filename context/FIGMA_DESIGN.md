# Blightsilver UI — Figma Design Reference

**File URL:** https://www.figma.com/design/ZYBC0dJhAERPQ7RCvNHMW0/Blightsilver-UI?node-id=0-1

## Screens

| Screen       | Node ID | Size       | Figma URL                                                                                               |
|--------------|---------|------------|---------------------------------------------------------------------------------------------------------|
| Main Menu    | 3:2     | 1280×720   | https://www.figma.com/design/ZYBC0dJhAERPQ7RCvNHMW0/Blightsilver-UI?node-id=3-2                       |
| Deck Builder | 8:2     | 1280×720   | https://www.figma.com/design/ZYBC0dJhAERPQ7RCvNHMW0/Blightsilver-UI?node-id=8-2                       |
| Game Board   | 8:234   | 1280×720   | https://www.figma.com/design/ZYBC0dJhAERPQ7RCvNHMW0/Blightsilver-UI?node-id=8-234                     |

## Design Tokens

### Background Colors
- Global bg: `#060810` = Color(0.024, 0.031, 0.063)
- Game board bg: `#04060d` = Color(0.016, 0.024, 0.051)

### Accent Colors (per button / affinity)
| Role           | Hex       | Godot Color                     |
|----------------|-----------|---------------------------------|
| Cyan / NEW GAME | `#2ebfff` | Color(0.18, 0.749, 1.0)        |
| Purple / Deck   | `#994dff` | Color(0.60, 0.302, 1.0)        |
| Green / VS AI   | `#2ee599` | Color(0.18, 0.898, 0.60)       |
| Gray / Settings | `#b3b3b3` | Color(0.702, 0.702, 0.702)     |
| Gold / Divine   | `#ffd933` | Color(1.0, 0.851, 0.20)        |
| Red / Trap      | `#ff4d4d` | Color(1.0, 0.302, 0.302)       |
| Teal / Tech     | `#00e5e5` | Color(0.0, 0.898, 0.898)       |
| Orange / Anima  | `#ff731a` | Color(1.0, 0.451, 0.102)       |
| Lime / Bio      | `#80f21a` | Color(0.502, 0.949, 0.102)     |
| Violet / Chaos  | `#a61ae5` | Color(0.651, 0.102, 0.898)     |
| Blue / Arcane   | `#338cff` | Color(0.20, 0.549, 1.0)        |
| Nature green    | `#33d94d` | Color(0.20, 0.851, 0.302)      |
| Cosmic cyan     | `#00e5e5` | Color(0.0, 0.898, 0.898)       |

### Godot Scene Mapping
| Figma Screen | Godot Scene                      |
|--------------|----------------------------------|
| Main Menu    | `res://scenes/main_menu.tscn`    |
| Deck Builder | `res://scenes/deck_builder.tscn` |
| Game Board   | `res://scenes/game_board.tscn`   |
