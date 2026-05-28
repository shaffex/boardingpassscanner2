<?php
/**
 * getFlightInfo.php
 *
 * JSON endpoint that takes a flight identifier and returns clean, structured
 * flight data sourced from FlightStats (Cirium).
 *
 * Usage:
 *   GET  getFlightInfo.php?flightCode=FR287
 *   GET  getFlightInfo.php?flightCode=FR287&date=2026-05-09
 *   GET  getFlightInfo.php?carrier=FR&flight=287
 *   GET  getFlightInfo.php?carrier=FR&flight=287&date=2026-05-09
 *
 * Response shape (success):
 *   {
 *     "found":        true,
 *     "carrierCode":  "FR",
 *     "carrierName":  "Ryanair",
 *     "flightNumber": 287,
 *     "flightCode":   "FR287",
 *     "flightId":     1382431661,
 *     "status":       "S",
 *     "state":        "currentDatePreFlight",
 *     "date":         "2026-05-09",
 *     "departure": {
 *       "airportCode":  "STN",
 *       "cityName":     "London",
 *       "countryCode":  "GB",
 *       "terminal":     null,
 *       "gate":         "50",
 *       "scheduledUTC": "2026-05-09T10:10:00.000Z",
 *       "estimatedUTC": "2026-05-09T10:10:00.000Z",
 *       "localTime":    "2026-05-09T11:10:00.000",
 *       "utcTime":      "2026-05-09T10:10:00.000Z"
 *     },
 *     "arrival": { ...same shape, plus "baggage"... },
 *     "delays": {}
 *   }
 *
 * On error / not found, returns 4xx/5xx with { "error": "..." }.
 */

declare(strict_types=1);

ini_set('display_errors', '1');
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('Access-Control-Allow-Origin: *');

// ============================================================================
// CONFIG
// ============================================================================
const FLIGHTSTATS_BASE = 'https://edge.flightstats.com/flight/segments/dep';
const FLIGHTSTATS_GUID = '679f8f0452a779ea:6a6a1c7:156dd340951:24f0';
const FLIGHTSTATS_RQID = 'i-kjmd01oh7gb';
const REQUEST_TIMEOUT  = 15;

// ============================================================================
// MAIN
// ============================================================================
[$carrierCode, $flightNumber] = parseFlightCode($_GET);
$flightDate                   = parseDate($_GET['date'] ?? gmdate('Y-m-d'));

$rawJson = fetchFlightStats($carrierCode, $flightNumber, $flightDate);
$result  = formatResponse($rawJson, $carrierCode, $flightNumber, $flightDate);

echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
exit;


// ============================================================================
// INPUT PARSING
// ============================================================================

/**
 * Accepts either ?flightCode=FR287 or ?carrier=FR&flight=287.
 * Returns [carrierCode, flightNumber] as uppercase strings.
 */
function parseFlightCode(array $params): array
{
    if (!empty($params['flightCode'])) {
        $raw = strtoupper(trim((string)$params['flightCode']));
        // IATA airline code is exactly 2 chars (letter+letter, letter+digit,
        // or digit+letter — see U2, B6, 2I, etc), followed by the 1–5 digit
        // flight number. Greedy {2,3} would mis-split "FR287" as "FR2"+"87".
        if (!preg_match('/^([A-Z0-9]{2})(\d{1,5})$/', $raw, $m)) {
            fail(400, "Invalid flightCode '$raw'. Expected 2-char IATA carrier + 1-5 digit flight (e.g. FR287, U22230, BA1859).");
        }
        return [$m[1], $m[2]];
    }

    $carrier = $params['carrier'] ?? null;
    $flight  = $params['flight']  ?? null;

    if (!$carrier || !$flight) {
        fail(400, 'Missing parameters. Use ?flightCode=FR287 or ?carrier=FR&flight=287.');
    }

    return [strtoupper(trim((string)$carrier)), trim((string)$flight)];
}

function parseDate(string $input): DateTimeImmutable
{
    // Accept ISO timestamps like "2026-06-02T13:30:00Z" by keeping the wallclock
    // date as specified (no UTC conversion). Pre-extracting the first 10 chars
    // preserves the date the caller intended even when the offset would shift it.
    $dateOnly = substr($input, 0, 10);

    $dt = DateTimeImmutable::createFromFormat('Y-m-d', $dateOnly);
    if (!$dt) {
        fail(400, "Invalid date '$input'. Expected YYYY-MM-DD or ISO 8601 timestamp.");
    }
    return $dt;
}


// ============================================================================
// UPSTREAM FETCH
// ============================================================================

function fetchFlightStats(string $carrier, string $flight, DateTimeImmutable $date): string
{
    $url = sprintf(
        '%s/%s/%s/%s/%s/%s?guid=%s&rqid=%s',
        FLIGHTSTATS_BASE,
        rawurlencode($carrier),
        rawurlencode($flight),
        $date->format('Y'),
        $date->format('m'),
        $date->format('d'),
        FLIGHTSTATS_GUID,
        FLIGHTSTATS_RQID
    );

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => REQUEST_TIMEOUT,
        CURLOPT_HTTPHEADER     => [
            'Host: edge.flightstats.com',
            'Accept: application/json',
            'User-Agent: FlightStats/8560 CFNetwork/1312 Darwin/21.0.0',
        ],
    ]);

    $body  = curl_exec($ch);
    $error = curl_error($ch);
    curl_close($ch);

    if ($body === false) {
        fail(502, 'Upstream fetch failed.', ['detail' => $error]);
    }

    return (string)$body;
}


// ============================================================================
// RESPONSE SHAPING
// ============================================================================

function formatResponse(
    string $rawJson,
    string $carrierCode,
    string $flightNumber,
    DateTimeImmutable $flightDate
): array {
    $data = json_decode($rawJson, true);
    if (!is_array($data)) {
        fail(502, 'Upstream returned invalid JSON.', ['raw' => substr($rawJson, 0, 500)]);
    }

    if (empty($data['segments'])) {
        return [
            'found'        => false,
            'carrierCode'  => $carrierCode,
            'flightNumber' => $flightNumber,
            'date'         => $flightDate->format('Y-m-d'),
            'message'      => 'Flight not found in flight database for given date.',
            'upstream'     => $data,
        ];
    }

    $seg = $data['segments'][0];
    $ops = $seg['operationalTimes'] ?? [];

    return [
        'found'        => true,
        'carrierCode'  => $data['carrierFsCode']      ?? $carrierCode,
        'carrierName'  => $data['carrierName']        ?? null,
        'flightNumber' => (int)($data['flightNumber'] ?? $flightNumber),
        'flightCode'   => ($data['carrierFsCode'] ?? $carrierCode)
                          . ($data['flightNumber'] ?? $flightNumber),
        'flightId'     => $seg['flightId']             ?? null,
        'status'       => $seg['status']               ?? null,
        'state'        => $seg['TargetedFlightState']  ?? null,
        'date'         => $flightDate->format('Y-m-d'),

        'departure' => [
            'airportCode'  => $seg['departureAirportFsCode']      ?? null,
            'cityName'     => $seg['departureAirportCityName']    ?? null,
            'countryCode'  => $seg['departureAirportCountryCode'] ?? null,
            'terminal'     => emptyToNull($seg['departureTerminal'] ?? ''),
            'gate'         => emptyToNull($seg['departureGate']     ?? ''),
            'scheduledUTC' => $ops['scheduledGateDeparture']['dateUtc'] ?? null,
            'estimatedUTC' => $ops['estimatedGateDeparture']['dateUtc'] ?? null,
            'localTime'    => $seg['departureTime']    ?? null,
            'utcTime'      => $seg['departureTimeUTC'] ?? null,
        ],

        'arrival' => [
            'airportCode'  => $seg['arrivalAirportFsCode']      ?? null,
            'cityName'     => $seg['arrivalAirportCityName']    ?? null,
            'countryCode'  => $seg['arrivalAirportCountryCode'] ?? null,
            'terminal'     => emptyToNull($seg['arrivalTerminal'] ?? ''),
            'gate'         => emptyToNull($seg['arrivalGate']     ?? ''),
            'baggage'      => emptyToNull($seg['baggage']         ?? ''),
            'scheduledUTC' => $ops['scheduledGateArrival']['dateUtc'] ?? null,
            'estimatedUTC' => $ops['estimatedGateArrival']['dateUtc'] ?? null,
            'localTime'    => $seg['arrivalTime']    ?? null,
            'utcTime'      => $seg['arrivalTimeUTC'] ?? null,
        ],

        'delays' => $seg['delays'] ?? new stdClass(),
    ];
}


// ============================================================================
// SMALL UTILITIES
// ============================================================================

function emptyToNull(mixed $value): ?string
{
    $v = trim((string)$value);
    return $v === '' ? null : $v;
}

function fail(int $code, string $message, array $extra = []): never
{
    http_response_code($code);
    echo json_encode(['error' => $message] + $extra, JSON_PRETTY_PRINT);
    exit;
}
