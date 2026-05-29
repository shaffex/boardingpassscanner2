<?php
ini_set('display_errors', '1');
error_reporting(E_ALL);

header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Access-Control-Allow-Origin: *');

include_once 'passkit/PKPass.php';
require_once __DIR__ . '/Database.php';

use PKPass\PKPass;

// ============================================================================
// INPUT
// ============================================================================
$barcodeText      = $_POST['barcodeText'] ?? '';
$flightDate       = $_POST['flightDate']  ?? '';   // ISO yyyy-mm-dd
$debug            = !empty($_POST['debug']);
$fieldsConfigJson = $_POST['fieldsConfig'] ?? '';
$barcodeType      = strtolower($_POST['barcodeType'] ?? 'pdf417');

$barcodeFormat = [
    'pdf417' => 'PKBarcodeFormatPDF417',
    'aztec'  => 'PKBarcodeFormatAztec',
    'qr'     => 'PKBarcodeFormatQR',
][$barcodeType] ?? 'PKBarcodeFormatPDF417';

if ($debug) {
    header('Content-Type: text/plain; charset=utf-8');
}

if ($barcodeText === '' || $flightDate === '') {
    http_response_code(400);
    echo 'barcodeText and flightDate are required';
    exit;
}

// In debug mode we ALSO echo each log line and skip emitting the binary pass
// at the end — so the response is a readable trace instead of a .pkpass.
function logd(bool $debug, string $tag, $value = null): void {
    if (!$debug) return;
    $isStructured = !(is_scalar($value) || $value === null);
    $compact = $isStructured
        ? json_encode($value, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)
        : (string) $value;
    error_log("[boardingpass] {$tag}: {$compact}");

    $pretty = $isStructured
        ? json_encode($value, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)
        : (string) $value;
    echo "[boardingpass] {$tag}: {$pretty}\n";
}

function saveBarcodeToDatabase(string $barcodeType, string $barcodeText, string $flightDate): void {
    try {
        $year = (int)substr($flightDate, 0, 4);
        if ($year < 1900 || $year > 3000) {
            $year = (int)date('Y');
        }

        $database = new Database();
        $database->add($barcodeType, $barcodeText, $year);
    } catch (Throwable $e) {
        Database::logFailure($e);
    }
}

logd($debug, 'input.barcodeText', $barcodeText);
logd($debug, 'input.flightDate',  $flightDate);
logd($debug, 'input.fieldsConfig', $fieldsConfigJson ?: '(none)');

saveBarcodeToDatabase($barcodeType, $barcodeText, $flightDate);

$fieldsConfig = [];
if ($fieldsConfigJson !== '') {
    $fieldsConfig = json_decode($fieldsConfigJson, true);
    if (!is_array($fieldsConfig)) {
        http_response_code(400);
        echo 'fieldsConfig must be a valid JSON object';
        exit;
    }
}

// ============================================================================
// PARSE BCBP MANDATORY SECTION (M1, 60 chars)
// ============================================================================
function parseBcbp(string $b): array {
    return [
        'passengerName' => trim(substr($b,  2, 20)),
        'pnr'           => trim(substr($b, 23,  7)),
        'fromCode'      =>      substr($b, 30,  3),
        'toCode'        =>      substr($b, 33,  3),
        'carrierCode'   => trim(substr($b, 36,  3)),
        'flightNumber'  => (int) trim(substr($b, 39, 5)),
        'compartment'   =>      substr($b, 47,  1),
        'seat'          => ltrim(trim(substr($b, 48, 4)), '0'),
    ];
}

$bcbp = parseBcbp($barcodeText);
[$paxFamily, $paxGiven] = array_pad(explode('/', $bcbp['passengerName'], 2), 2, '');

logd($debug, 'bcbp.parsed', $bcbp);

function normalizeFields(array $fields): array {
    $normalized = [];
    foreach ($fields as $field) {
        if (!is_array($field)) {
            continue;
        }
        if (!isset($field['key'], $field['label'], $field['value'])) {
            continue;
        }
        $normalized[] = $field;
    }
    return $normalized;
}

$defaultFields = [
    'headerFields' => [
        [
            'key'   => 'flight',
            'label' => 'FLIGHT',
            'value' => "{$bcbp['carrierCode']} {$bcbp['flightNumber']}"
        ]
    ],
    'primaryFields' => [
        ['key' => 'from', 'label' => $bcbp['fromCode'], 'value' => $bcbp['fromCode']],
        ['key' => 'to',   'label' => $bcbp['toCode'],   'value' => $bcbp['toCode']],
    ],
    'auxiliaryFields' => [],
    'secondaryFields' => [
        [
            'key'   => 'passenger',
            'label' => 'PASSENGER',
            'value' => $bcbp['passengerName']
        ],
        [
            'key'           => 'seat',
            'label'         => 'SEAT',
            'value'         => $bcbp['seat'],
            'textAlignment' => 'PKTextAlignmentRight'
        ],
    ],
    'backFields' => [
        ['key' => 'pnr', 'label' => 'BOOKING REF', 'value' => $bcbp['pnr']],
    ],
];

$fieldsConfig = array_merge(
    $defaultFields,
    array_intersect_key($fieldsConfig, $defaultFields)
);

$headerFields    = normalizeFields($fieldsConfig['headerFields'] ?? []);
$primaryFields   = normalizeFields($fieldsConfig['primaryFields'] ?? []);
$auxiliaryFields = normalizeFields($fieldsConfig['auxiliaryFields'] ?? []);
$secondaryFields = normalizeFields($fieldsConfig['secondaryFields'] ?? []);
$backFields      = normalizeFields($fieldsConfig['backFields'] ?? []);

logd($debug, 'fieldsConfig.normalized', [
    'headerFields'    => $headerFields,
    'primaryFields'   => $primaryFields,
    'auxiliaryFields' => $auxiliaryFields,
    'secondaryFields' => $secondaryFields,
    'backFields'      => $backFields,
]);

// ============================================================================
// IANA tz lookup.
//
// Preferred: derive the offset from localTime vs utcTime in the API response
// and ask PHP for any zone that matches at the flight date (works regardless of
// country). Falls back to country code, then to Etc/GMT±N.
// ============================================================================
function tzForCountry(?string $cc): ?string {
    if (!$cc) return null;
    $ids = @DateTimeZone::listIdentifiers(DateTimeZone::PER_COUNTRY, $cc);
    return $ids[0] ?? null;
}

function tzFromLocalAndUtc(?string $localTime, ?string $utcTime, ?string $countryCode = null): ?string {
    if (!$localTime || !$utcTime) return null;

    try {
        // Strip any trailing tz/Z from the local wallclock then parse it as UTC,
        // so the timestamp difference gives the wallclock offset in seconds.
        $localNaive = preg_replace('/[Zz]$|[+\-]\d{2}:?\d{2}$/', '', $localTime);
        $utc        = new DateTime($utcTime,    new DateTimeZone('UTC'));
        $local      = new DateTime($localNaive, new DateTimeZone('UTC'));
        $offset     = $local->getTimestamp() - $utc->getTimestamp();
    } catch (Exception $e) {
        return null;
    }

    // Pick a zone whose offset AT THE FLIGHT DATE matches — not just whose
    // standard-time offset matches. timezone_name_from_abbr() ignores the date,
    // so e.g. for -4h in May it can pick a zone that's standard -4 in winter
    // but +3 in summer (DST), causing a 1-hour drift on the boarding pass.
    $countryZones = $countryCode
        ? (DateTimeZone::listIdentifiers(DateTimeZone::PER_COUNTRY, $countryCode) ?: [])
        : [];
    $allZones = DateTimeZone::listIdentifiers();

    foreach (array_merge($countryZones, $allZones) as $name) {
        try {
            $tz = new DateTimeZone($name);
            if ($tz->getOffset($utc) === $offset) {
                return $name;
            }
        } catch (Exception $e) {
            continue;
        }
    }

    // Etc/GMT signs are inverted (Etc/GMT-3 = UTC+3).
    $hours = (int) ($offset / 3600);
    if ($hours === 0) return 'UTC';
    $sign = $hours > 0 ? '-' : '+';
    return 'Etc/GMT' . $sign . abs($hours);
}

function resolveTimeZone(array $leg): ?string {
    $tz = tzFromLocalAndUtc(
        $leg['localTime']   ?? null,
        $leg['utcTime']     ?? null,
        $leg['countryCode'] ?? null
    );
    if ($tz) return $tz;
    return tzForCountry($leg['countryCode'] ?? null);
}

// Builds one Apple-semantic seat entry from the BCBP seat ("35D") + compartment
// code ("Y", "J", …). seatType uses a narrow-body (3-3) heuristic and will be
// wrong for widebody layouts; omitted entirely if the letter is unknown.
//
// Wallet composes the seat tile as seatRow + seatNumber, so seatNumber holds
// only the letter — passing the full "35D" in both fields renders "3535D".
function seatInfo(string $rawSeat, string $compartment): array {
    if ($rawSeat === '') return [];

    $row    = preg_replace('/[^0-9]/', '', $rawSeat) ?? '';
    $letter = strtoupper(preg_replace('/[^A-Za-z]/', '', $rawSeat) ?? '');

    $info = [];
    if ($letter !== '') {
        $info['seatNumber'] = $letter;
    } elseif ($row !== '') {
        $info['seatNumber'] = $row;
    } else {
        $info['seatNumber'] = $rawSeat;
    }
    if ($row !== '') {
        $info['seatRow'] = $row;
    }

    $positionMap = [
        'A' => 'window', 'F' => 'window', 'K' => 'window',
        'C' => 'aisle',  'D' => 'aisle',
        'B' => 'middle', 'E' => 'middle',
    ];
    if (isset($positionMap[$letter])) {
        $info['seatType'] = $positionMap[$letter];
    }

    $cabinMap = [
        'Y' => 'Economy', 'W' => 'Premium Economy',
        'C' => 'Business', 'J' => 'Business',
        'F' => 'First',    'A' => 'First',
    ];
    $code = strtoupper($compartment);
    if (isset($cabinMap[$code])) {
        $info['seatDescription'] = $cabinMap[$code];
    }

    return $info;
}

// ============================================================================
// RESOLVED FIELDS
// ============================================================================
$AIRLINE_CODE  = $bcbp['carrierCode'];
$AIRLINE_NAME  = $bcbp['carrierCode'];
$FLIGHT_NUMBER = $bcbp['flightNumber'];

$FROM_CODE = $bcbp['fromCode'];
$FROM_CITY = $bcbp['fromCode'];
$TO_CODE   = $bcbp['toCode'];
$TO_CITY   = $bcbp['toCode'];

$BG_COLOR    = $_POST['backgroundColor'] ?? 'rgb(7,53,144)';
$FG_COLOR    = $_POST['foregroundColor'] ?? 'rgb(255,255,255)';
$LABEL_COLOR = $_POST['labelColor']      ?? 'rgb(255,255,255)';

// ============================================================================
// PASS
// ============================================================================
$pass = new PKPass('passkit/Certificates.p12', 'kokotaz');

$passData = [
    'formatVersion'      => 1,
    'passTypeIdentifier' => 'pass.com.shaffex.boardingpass',
    'serialNumber'       => hash('sha256', $barcodeText),
    'teamIdentifier'     => 'X47885HM53',

    'organizationName'   => $AIRLINE_NAME,
    'description'        => 'Boarding Pass',
    'logoText'           => ($_POST['logoText'] ?? '') !== '' ? $_POST['logoText'] : $AIRLINE_NAME,

    'foregroundColor'    => $FG_COLOR,
    'backgroundColor'    => $BG_COLOR,
    'labelColor'         => $LABEL_COLOR,

    'suppressStripShine' => true,

    'boardingPass' => [
        'transitType' => 'PKTransitTypeAir',
        'headerFields'    => $headerFields,
        'primaryFields'   => $primaryFields,
        'auxiliaryFields' => $auxiliaryFields,
        'secondaryFields' => $secondaryFields,
        'backFields'      => $backFields,
    ],

    'barcode' => [
        'format'          => $barcodeFormat,
        'message'         => $barcodeText,
        'messageEncoding' => 'utf-8'
    ],
];

// ============================================================================
// DONE: static boarding pass without semantics or external flight lookup.
// ============================================================================
logd($debug, 'fallback', 'generic boarding pass (no semantics)');

// ============================================================================
// APPLY & EMIT
// ============================================================================
$pass->setData($passData);

$pass->addFile('passkit/images/icon.png');
$pass->addFile('passkit/images/icon@2x.png');
$pass->addFile('passkit/images/logo.png');
$pass->addFile('passkit/images/logo@2x.png');

logd($debug, 'passData', $passData);

if ($debug) {
    logd($debug, 'pass.skipped', 'debug mode — pass not generated');
} else {
    if (!$pass->create(true)) {
        echo 'Error: ' . $pass->getError();
    }
}
