<?php
// ============================================================================
// Lookup.php
//
// Maps codes found in a BCBP barcode to human-readable names using the CSV
// reference files in Data/:
//   - airlines.csv  (code,name,country)        airline IATA code  -> name
//   - airports.csv  (code,name,city,country)   airport IATA code  -> city
//
// Each file is parsed once per request and cached in a static map. Lookups are
// case-insensitive on the code. Returns null when the code is unknown so the
// caller can fall back to showing the raw code.
// ============================================================================

/**
 * Builds (once) and returns an associative map [code => value] from a CSV file.
 *
 * @param string $file       Absolute path to the CSV file.
 * @param int    $valueIndex Column index of the value to map the code to.
 * @return array<string,string>
 */
function loadCodeMap(string $file, int $valueIndex): array
{
    static $cache = [];

    $cacheKey = $file . '#' . $valueIndex;
    if (isset($cache[$cacheKey])) {
        return $cache[$cacheKey];
    }

    $map = [];
    $handle = @fopen($file, 'r');
    if ($handle !== false) {
        // Pass all CSV control args explicitly ($escape = '') so PHP 8.4+ does
        // not emit a deprecation notice about the changing default.
        $header = fgetcsv($handle, null, ',', '"', ''); // skip header row
        while (($row = fgetcsv($handle, null, ',', '"', '')) !== false) {
            if (!isset($row[0], $row[$valueIndex])) {
                continue;
            }
            $code  = strtoupper(trim($row[0]));
            $value = trim($row[$valueIndex]);
            // Keep the first occurrence so duplicate codes don't get clobbered.
            if ($code !== '' && $value !== '' && !isset($map[$code])) {
                $map[$code] = $value;
            }
        }
        fclose($handle);
    }

    $cache[$cacheKey] = $map;
    return $map;
}

/**
 * Resolves an airline (carrier) code to its airline name.
 *
 * @return string|null Airline name, or null if the code is unknown.
 */
function lookupAirlineName(string $code): ?string
{
    $code = strtoupper(trim($code));
    if ($code === '') {
        return null;
    }
    $map = loadCodeMap(__DIR__ . '/Data/airlines.csv', 1); // name column
    return $map[$code] ?? null;
}

/**
 * Resolves a 3-letter airport (IATA) code to its city name.
 *
 * @return string|null City name, or null if the code is unknown.
 */
function lookupAirportCity(string $code): ?string
{
    $code = strtoupper(trim($code));
    if ($code === '') {
        return null;
    }
    $map = loadCodeMap(__DIR__ . '/Data/airports.csv', 2); // city column
    return $map[$code] ?? null;
}
