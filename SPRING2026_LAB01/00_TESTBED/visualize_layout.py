# %%
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import matplotlib.patches as patches

def parse_shape(shape_hex):
    # Convert hex string to integer
    if( not shape_hex or shape_hex.startswith("//") or shape_hex.startswith("endl")):
        return 0, 0, 0, 0, 0

    parts = [int(p) for p in shape_hex.split()]
    
    # Extract fields based on your specification
    layer_id = parts[0]
    x1 = parts[1]
    y1 = parts[2]
    x2 = parts[3]
    y2 = parts[4]

    return layer_id, x1, y1, x2, y2


# %%
def plot_layout(filename):
    fig, ax = plt.subplots(figsize=(8, 8))
    
    # Layer styling and Priority (zorder)
    # Priority Mapping (Higher zorder = stays on top)
    # NW:1, NP/PP:2, OD:3, PO:4, M1:5 (with hatch), CONT:6
    styles = {
        1: {'fc': 'lightgreen', 'ec': 'none',   'alpha': 1.0, 'z': 6, 'label': 'CO'},
        2: {'fc': 'red',        'ec': 'none',   'alpha': 0.8, 'z': 3, 'label': 'OD'},
        3: {'fc': 'blue',       'ec': 'none',   'alpha': 0.8, 'z': 4, 'label': 'PO'},
        4: {'fc': 'none',       'ec': 'skyblue','alpha': 1.0, 'z': 5, 'hatch': '...', 'label': 'M1'},
        5: {'fc': 'none',       'ec': 'yellow', 'alpha': 1.0, 'z': 2, 'lw': 2, 'label': 'NP'},
        6: {'fc': 'none',       'ec': 'purple', 'alpha': 1.0, 'z': 2, 'lw': 2, 'label': 'PP'},
        7: {'fc': 'none',       'ec': 'white',  'alpha': 1.0, 'z': 1, 'lw': 3, 'label': 'NW'}
    }

    try:
        with open(filename, 'r') as f:
            shapes = f.readlines()
            
        for line in shapes[:16]: # Process up to 16 shapes
            input_string = line.strip()
            if( not input_string or input_string.startswith("//") or input_string.startswith("endl")):
                continue
            
            layer_id, x1, y1, x2, y2 = parse_shape(input_string)

            if layer_id == 0 or layer_id not in styles:
                continue
            
            s = styles[layer_id]
            # Create rectangle with zorder for layer priority
            rect = patches.Rectangle(
                (x1, y1), x2-x1, y2-y1, 
                facecolor=s.get('fc'), 
                edgecolor=s.get('ec'),
                hatch=s.get('hatch'),
                linewidth=s.get('lw', 1),
                alpha=s.get('alpha'),
                zorder=s['z'], # Higher numbers are drawn on top
                label=s.get('label') # Add label for legend
            )
            ax.add_patch(rect)

    except FileNotFoundError:
        print(f"Error: {filename} not found.")
        return

    # Grid and Axis Setup
    ax.set_xlim(-1, 16)
    ax.set_ylim(-1, 16)

    # keep tick marks every 1 but only show labels for multiples of 5
    ax.set_xticks(range(16))
    ax.set_yticks(range(16))
    ax.set_xticklabels([str(t) if t % 5 == 0 else "" for t in range(16)])
    ax.set_yticklabels([str(t) if t % 5 == 0 else "" for t in range(16)])

    ax.grid(which='major', color='gray', linestyle='-', linewidth=0.5, alpha=0.3)
    ax.set_aspect('equal')
    ax.set_facecolor('#4e4e4e') # Dark background for better visibility
    plt.title("DRC Exercise: 32x32 Layout Visualization")
    
    # Create legend (avoiding duplicates)
    handles, labels = plt.gca().get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    plt.legend(by_label.values(), by_label.keys(), loc='upper right', bbox_to_anchor=(1.2, 1), facecolor='#8e8e8e', edgecolor='white', framealpha=0.9)

    plt.show()

# %%
# Usage
# Ensure visual_layout.txt contains one hex value (e.g., 20843F) per line
plot_layout('../00_TESTBED/visual_layout.txt')

# %%



