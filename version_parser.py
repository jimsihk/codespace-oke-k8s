import re

# Read input from file
file_path = '/tmp/test_result.txt'
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
                        version = next_line.split('v')[1].strip()
                        versions[tool] = version
                        break
            elif tool == 'kdash':
                # Extract version from "kdash X.Y.Z"
                match = re.search(r'kdash (\S+)', version_info)
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
