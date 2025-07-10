# Address Geocoding Script Usage

This Swift script converts physical addresses to GPS coordinates (latitude/longitude) using Apple's MapKit geocoding service.

## Prerequisites

### System Requirements
- **macOS only** - This script requires Apple's MapKit framework and will not work on Linux or Windows
- **Swift Runtime** - macOS 10.15 (Catalina) or later includes Swift runtime by default
- **Internet Connection** - Required for geocoding API calls

### Installation Check
Verify Swift is available:
```bash
swift --version
```

If Swift is not installed, install Xcode Command Line Tools:
```bash
xcode-select --install
```

## Usage

### Basic Usage
```bash
./geocode_addresses.swift input.csv output.csv
```

### Input CSV Format
The input CSV file should contain two columns:
- Column 1: ID (integer)
- Column 2: Address (physical address string)

**Example input.csv:**
```csv
1,Højgårds Vænge 26, 2880 Bagsværd, Danmark
2,Times Square, New York, NY, USA
3,Champs-Élysées, Paris, France
```

### Output CSV Format
The script generates a CSV with four columns:
- ID: Original ID from input
- Address: Original address from input
- Latitude: GPS latitude coordinate
- Longitude: GPS longitude coordinate

**Example output.csv:**
```csv
ID,Address,Latitude,Longitude
1,"Højgårds Vænge 26, 2880 Bagsværd, Danmark",55.7681,12.4536
2,"Times Square, New York, NY, USA",40.7580,-73.9855
3,"Champs-Élysées, Paris, France",48.8698,2.3076
```

## Running the Script

### Step 1: Make Script Executable
```bash
chmod +x geocode_addresses.swift
```

### Step 2: Run with Test Data
```bash
./geocode_addresses.swift test_addresses.csv output.csv
```

### Step 3: Verify Output
```bash
cat output.csv
```

## Important Notes

### Rate Limiting
- The script includes a 0.1-second delay between requests to avoid overwhelming the geocoding service
- Large address lists may take considerable time to process

### Error Handling
- Addresses that cannot be geocoded will have empty latitude/longitude fields
- Invalid or malformed CSV lines are skipped with warnings
- Network errors and API failures are logged

### Data Privacy
- All geocoding requests are sent to Apple's servers
- No address data is stored locally beyond the output file
- Consider privacy implications for sensitive location data

## Troubleshooting

### Common Issues

**"Permission denied" error:**
```bash
chmod +x geocode_addresses.swift
```

**"No such file or directory" error:**
- Ensure input CSV file exists and path is correct
- Use absolute paths if needed: `/full/path/to/input.csv`

**"Swift command not found":**
- Install Xcode Command Line Tools: `xcode-select --install`
- Restart terminal after installation

**Network/geocoding errors:**
- Check internet connection
- Verify address format is recognizable
- Some addresses may not be found in Apple's database

### Testing
Use the included `test_addresses.csv` file to verify the script works:
```bash
./geocode_addresses.swift test_addresses.csv test_output.csv
```

## Performance
- Processing ~10 addresses: ~5-10 seconds
- Processing ~100 addresses: ~2-3 minutes
- Processing ~1000 addresses: ~20-30 minutes

For large datasets, consider running in batches or using a more robust geocoding service.