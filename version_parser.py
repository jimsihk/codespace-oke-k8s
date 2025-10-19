import re
import sys

# Check if a file name is provided as a command-line argument
if len(sys.argv) != 2:
    print("Error: Please provide a file name as an argument.")
    print("Usage: python parse_versions.py <filename>")
    exit(1)

# Get file path from command-line argument
file_path = sys.argv[1]

# Read input from file
try:
    with open(file_path, 'r') as file:
        text = file.read()
except FileNotFoundError:
    print(f"Error: File {file_path} not found.")
    exit(1)

# Dictionary to store tool versions
versions = {}

# Process each line
for line in text.splitlines():
    line = line.strip()
    # Skip empty lines or decorative lines
    if not line or line.startswith('___') or line.startswith('|'):
        continue
    
    # Match lines with tool and version
    if line.startswith('-'):
        # Split on colon and strip
        tool_version = line[1:].split(':', 1)
        if len(tool_version) == 2:
            tool, version_info = [x.strip() for x in tool_version]
            # Extract version for specific cases
            if tool == 'kubectl':
                # Look for the next line with Client Version
                next_lines = text.splitlines()[text.splitlines().index(line)+1:]
                for next_line in next_lines:
                    if 'Client Version:' in next_line:
                        version = next_line.split('v')[1].strip()
                        versions[tool] = version
                        break
            elif tool == 'helm':
                # Extract version from version.BuildInfo
                match = re.search(r'Version:"v?([^"]+)"', version_info)
                if match:
                    versions[tool] = match.group(1)
            elif tool == 'git':
                # Extract version from "git version X.Y.Z"
                match = re.search(r'git version (\S+)', version_info)
                if match:
                    versions[tool] = match.group(1)
            elif tool == 'k9s':
                # Look for the next line with Version
                next_lines = text.splitlines()[text.splitlines().index(line)+1:]
                for next_line in next_lines:
                    if 'Version:' in next_line:
                        if 'v' in next_line:
                            version = next_line.split('v')[1].strip()
                        else:
                            # Step 1: Remove ANSI escape codes
                            cleaned_output = re.sub(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])', '', next_line)
                            # Step 2: Clean the input by keeping only alphanumeric characters, periods, and colons
                            cleaned_output = re.sub(r'[^a-zA-Z0-9.:]', '', cleaned_output)
                            print(f'cleaned_output=[{cleaned_output}]')
                            # Step 3: Use regex to extract version number
                            match = re.search(r'Version:(\S+)', cleaned_output)
                            version = match.group(1)
                        versions[tool] = version
                        break
            elif tool == 'kdash':
                # Extract version from "kdash X.Y.Z"
                match = re.search(r'kdash (\S+)', version_info)
                if match:
                    versions[tool] = match.group(1)
            elif tool == 'python':
                # Extract version from "Python X.Y.Z"
                match = re.search(r'Python (\S+)', version_info)
                if match:
                    versions[tool] = match.group(1)
            else:
                # Direct version
                versions[tool] = version_info

# Output in markdown table format without ===
print('| Tool | Version |')
print('|--|--|')
for tool, version in versions.items():
    print(f'| {tool} | {version} |')
