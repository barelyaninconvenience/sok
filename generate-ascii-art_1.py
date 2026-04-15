#!/usr/bin/env python3
"""
SON OF KLEM ASCII Art Generator
Generates ornate ASCII art for PowerShell headers
"""

def generate_torus(radius=8, tube=3):
    """Generate a geometric torus using ASCII characters"""
    torus = []
    height = radius * 2 + 1
    width = radius * 4 + 1
    
    for y in range(height):
        line = []
        for x in range(width):
            # Center coordinates
            cx = width // 2
            cy = height // 2
            
            # Distance from center
            dx = x - cx
            dy = (y - cy) * 2  # Adjust for character aspect ratio
            
            dist_from_center = (dx**2 + dy**2) ** 0.5
            
            # Torus equation (simplified 2D projection)
            if abs(dist_from_center - radius) < tube:
                # Inner ring - denser
                if abs(dist_from_center - radius) < tube * 0.5:
                    line.append('█')
                else:
                    line.append('▓')
            elif abs(dist_from_center - radius) < tube + 1:
                line.append('░')
            else:
                line.append(' ')
        
        torus.append(''.join(line))
    
    return torus

def generate_gothic_letters():
    """
    Generate KaiserzeitGotisch-inspired letters using extended ASCII
    Focus on ornate, calligraphic style
    """
    
    # Gothic-style letters with flourishes
    letters = {
        'S': [
            "  ╔═══╗  ",
            " ╔╝   ╚╗ ",
            " ╚═══╗ ║ ",
            "  ╔══╝ ║ ",
            " ╔╝   ╔╝ ",
            " ╚════╝  "
        ],
        'O': [  # Will be replaced with torus for "of"
            "  ╔═══╗  ",
            " ╔╝   ╚╗ ",
            " ║     ║ ",
            " ║     ║ ",
            " ╚╗   ╔╝ ",
            "  ╚═══╝  "
        ],
        'N': [
            " ╔╗   ╔╗ ",
            " ║╚╗  ║║ ",
            " ║ ╚╗ ║║ ",
            " ║  ╚╗║║ ",
            " ║   ╚╝║ ",
            " ╚═════╝ "
        ],
        'F': [
            " ╔═════╗ ",
            " ║      ║",
            " ║═══╗  ║",
            " ║   ║   ",
            " ║        ",
            " ╚═══════"
        ],
        'K': [
            " ╔╗   ╔╗ ",
            " ║║  ╔╝  ",
            " ║╚═╗    ",
            " ║╔═╝    ",
            " ║║  ╚╗  ",
            " ╚╝   ╚╗ "
        ],
        'L': [
            " ╔╗      ",
            " ║║      ",
            " ║║      ",
            " ║║      ",
            " ║║      ",
            " ╚══════╗"
        ],
        'E': [
            " ╔══════╗",
            " ║       ",
            " ║═══╗   ",
            " ║   ║   ",
            " ║       ",
            " ╚══════╗"
        ],
        'M': [
            " ╔╗   ╔╗ ",
            " ║╚╗ ╔╝║ ",
            " ║ ╚═╝ ║ ",
            " ║     ║ ",
            " ║     ║ ",
            " ╚═════╝ "
        ]
    }
    
    return letters

def combine_letters(text, letters, torus_lines=None, torus_pos=None):
    """Combine individual letter arrays into full text"""
    words = text.split()
    result_lines = [''] * 6  # 6 lines tall
    
    for word_idx, word in enumerate(words):
        # Add spacing between words
        if word_idx > 0:
            for i in range(6):
                result_lines[i] += '    '
        
        for char_idx, char in enumerate(word):
            char_upper = char.upper()
            
            # Use torus for 'O' in 'of' if provided
            if torus_lines and torus_pos == (word_idx, char_idx):
                for i in range(min(6, len(torus_lines))):
                    if i < len(torus_lines):
                        result_lines[i] += torus_lines[i] + ' '
                    else:
                        result_lines[i] += ' ' * (len(torus_lines[0]) + 1)
            elif char_upper in letters:
                for i in range(6):
                    result_lines[i] += letters[char_upper][i] + ' '
            else:
                # Unknown character - use spaces
                for i in range(6):
                    result_lines[i] += ' ' * 10
    
    return result_lines

# Generate the art
print("Generating SON OF KLEM ASCII art...")
print()

letters = generate_gothic_letters()
torus = generate_torus(radius=4, tube=2)

# Find position of 'o' in 'of'
torus_position = (1, 0)  # Second word (of), first character (o)

# Generate full text
lines = combine_letters('SON OF KLEM', letters, torus, torus_position)

# Output
print("Gothic-style ASCII Art:")
print("="*120)
for line in lines:
    print("   " + line)
print("="*120)
print()

# Also output simple version for fallback
print("Simple fallback version:")
print("="*120)
simple = combine_letters('SON OF KLEM', letters)
for line in simple:
    print("   " + line)
print("="*120)

print()
print("Copy the version you prefer into your PowerShell scripts!")
