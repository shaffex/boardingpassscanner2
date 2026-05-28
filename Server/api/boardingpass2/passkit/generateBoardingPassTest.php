<?php
ini_set('display_errors', '1');
error_reporting(E_ALL);

header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

include_once 'PKPass.php';

use PKPass\PKPass;

// ============================================================================
// REAL FLIGHT DATA
// ============================================================================
$AIRLINE_CODE   = 'FR';
$FLIGHT_NUMBER  = 984;
$AIRLINE_NAME   = 'Ryanair';

$FROM_CODE      = 'STN';
$FROM_CITY      = 'London';
$FROM_TZ        = 'Europe/London';            // IANA tz for STN

$TO_CODE        = 'PSR';
$TO_CITY        = 'Pescara';
$TO_TZ          = 'Europe/Rome';            // IANA tz for PSR

// passengerName must be a structured object per Apple's semantic spec.
// BCBP convention is LASTNAME/FIRSTNAME — split here.
$PAX_FAMILY     = 'POPOVEC';
$PAX_GIVEN      = 'PETER';
$PASSENGER_NAME = "{$PAX_FAMILY}/{$PAX_GIVEN}";  // for legacy display + BCBP
$BOOKING_REF    = 'XJ1G2P';
$SEAT           = '12A';

// Per FlightInfo response: departureTerminal empty, arrivalGate empty.
$DEP_TERMINAL   = '';
$DEP_GATE       = '77';

$ARR_TERMINAL   = 'T7';
$ARR_GATE       = '';

$BG_COLOR       = 'rgb(7,53,144)';      // Ryanair navy
$FG_COLOR       = 'rgb(255,255,255)';

// ============================================================================
// TODAY'S FR287 STN→DUB — sourced directly from FlightInfo / Cirium response
// (flightId 1382431661, TargetedFlightState "currentDatePreFlight").
//   Sched dep 11:10 BST (10:10Z) | Sched arr 12:30 IST (11:30Z) — same day
//   No delays — current* equals scheduled.
// ============================================================================
$scheduledDeparture = '2026-05-10T20:25:00.000Z';   // 11:10 BST scheduled

//$actualDeparture    = '2026-05-09T10:10:00Z';   // no delay yet

$scheduledArrival   = '2026-05-10T22:50:00.000Z';   // 12:30 IST scheduled

//$estimatedArrival   = '2026-05-09T11:30:00Z';   // no delay yet

$boardingTime       = '2026-05-10T20:01:00.000Z';   // ~30 min before scheduled dep

// ============================================================================
// BCBP BARCODE
// ============================================================================
$julianToday = str_pad((int)gmdate('z') + 1, 3, '0', STR_PAD_LEFT); // today

$paxPadded     = str_pad($PASSENGER_NAME, 20);
$pnrPadded     = str_pad($BOOKING_REF, 7);
$carrierPadded = str_pad($AIRLINE_CODE, 3);
$flightPadded  = str_pad((string)$FLIGHT_NUMBER, 4, '0', STR_PAD_LEFT) . ' ';

$barcodeText =
    "M1{$paxPadded} {$pnrPadded}" .
    "{$FROM_CODE}{$TO_CODE}{$carrierPadded}" .
    "{$flightPadded}{$julianToday}Y012A0056 100";

// ============================================================================
// CREATE PASS
// ============================================================================
$pass = new PKPass('Certificates.p12', 'kokotaz');

// ============================================================================
// PASS DATA
// ============================================================================
$passData = [

    'formatVersion'      => 1,
    'passTypeIdentifier' => 'pass.com.shaffex.boardingpass',
    'serialNumber'       => hash('sha256', $barcodeText),
    'teamIdentifier'     => 'X47885HM53',

    // Opts the pass into Wallet's new semantic boarding pass style. Without
    // this, Wallet renders the pass as a legacy boardingPass and the
    // semantics-driven live tracker tile never activates.
    'preferredStyleSchemes' => ['semanticBoardingPass', 'boardingPass'],

    'organizationName'   => $AIRLINE_NAME,
    'description'        => 'Boarding Pass',
    'logoText'           => $AIRLINE_NAME,

    'foregroundColor'    => $FG_COLOR,
    'backgroundColor'    => $BG_COLOR,
    'labelColor'         => $FG_COLOR,

    'suppressStripShine' => true,

    // IMPORTANT:
    // Use REAL flight departure time
    'relevantDate'       => $scheduledDeparture,

    // ========================================================================
    // BOARDING PASS
    // ========================================================================
    'boardingPass' => [

        'transitType' => 'PKTransitTypeAir',

        'headerFields' => [
            [
                'key'   => 'flight',
                'label' => 'FLIGHT',
                'value' => "{$AIRLINE_CODE} {$FLIGHT_NUMBER}"
            ]
        ],

        'primaryFields' => [
            [
                'key'   => 'from',
                'label' => $FROM_CITY,
                'value' => $FROM_CODE
            ],
            [
                'key'   => 'to',
                'label' => $TO_CITY,
                'value' => $TO_CODE
            ]
        ],

        // 'secondaryFields' => [
        //     [
        //         'key'   => 'passenger',
        //         'label' => 'PASSENGER',
        //         'value' => $PASSENGER_NAME
        //     ],
        //     [
        //         'key'           => 'seat',
        //         'label'         => 'SEAT',
        //         'value'         => $SEAT,
        //         'textAlignment' => 'PKTextAlignmentRight'
        //     ]
        // ],

        // 'auxiliaryFields' => [
        //     [
        //         'key'   => 'gate',
        //         'label' => 'GATE',
        //         'value' => $DEP_GATE
        //     ],
        //     [
        //         'key'           => 'terminal',
        //         'label'         => 'TERMINAL',
        //         'value'         => $DEP_TERMINAL,
        //         'textAlignment' => 'PKTextAlignmentRight'
        //     ]
        // ],

        'backFields' => [
            [
                'key'   => 'pnr',
                'label' => 'BOOKING REF',
                'value' => $BOOKING_REF
            ]
        ]
    ],

    // ========================================================================
    // BARCODE
    // ========================================================================
    'barcode' => [
        'format'          => 'PKBarcodeFormatPDF417',
        'message'         => $barcodeText,
        'messageEncoding' => 'utf-8'
    ],

    // ========================================================================
    // SEMANTICS — only Apple's required tags for semanticBoardingPass.
    // Per Apple's spec, omitting any of these falls back to legacy boarding pass.
    // ========================================================================
    'semantics' => [
        'airlineCode'                 => $AIRLINE_CODE,
        'flightNumber'                => $FLIGHT_NUMBER,

        'departureAirportCode'        => $FROM_CODE,
        'departureCityName'           => $FROM_CITY,
        'departureLocationTimeZone'   => $FROM_TZ,

        'destinationAirportCode'      => $TO_CODE,
        'destinationCityName'         => $TO_CITY,
        'destinationLocationTimeZone' => $TO_TZ,

        'originalDepartureDate'       => $scheduledDeparture,
        'originalBoardingDate'        => "$boardingTime",
        'originalArrivalDate'         => $scheduledArrival,

        'passengerName' => [
            'givenName'  => $PAX_GIVEN,
            'familyName' => $PAX_FAMILY,
        ],
    ]
];

// ============================================================================
// APPLY DATA
// ============================================================================
$pass->setData($passData);

// ============================================================================
// REQUIRED IMAGES
// ============================================================================
$pass->addFile('images/icon.png');
$pass->addFile('images/icon@2x.png');

$pass->addFile('images/logo.png');
$pass->addFile('images/logo@2x.png');

// Optional
// $pass->addFile('images/strip.png');
// $pass->addFile('images/strip@2x.png');

// ============================================================================
// CREATE PASS
// ============================================================================
if (!$pass->create(true)) {
    echo 'Error: ' . $pass->getError();
}