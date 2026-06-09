<?php
declare(strict_types=1);

/**
 * Hourly pass-rate alert — intended to be run from cron, e.g. every hour:
 *
 *   0 * * * * /usr/bin/php /home/.../api/boardingpass2/passRateAlert.php >> /home/.../passRateAlert.log 2>&1
 *
 * Counts boarding passes created in the last WINDOW_MINUTES and emails
 * ALERT_EMAIL when the count exceeds ALERT_THRESHOLD. Prints a one-line
 * summary to stdout so cron logs stay readable.
 *
 * Manual run / dry-run:
 *   php passRateAlert.php          # checks and emails if over threshold
 *   php passRateAlert.php --dry    # checks and prints, never emails
 */

require_once __DIR__ . '/Database.php';

const ALERT_EMAIL     = 'peter.popovec@gmail.com';
const ALERT_THRESHOLD = 3;   // alert when count is strictly greater than this
const WINDOW_MINUTES  = 60;  // look-back window

$dryRun = in_array('--dry', $argv ?? [], true);

try {
    $database = new Database();
    $count    = $database->countSinceMinutes(WINDOW_MINUTES);
} catch (Throwable $e) {
    fwrite(STDERR, sprintf("[%s] passRateAlert ERROR: %s\n", date('Y-m-d H:i:s'), $e->getMessage()));
    exit(1);
}

$overThreshold = $count > ALERT_THRESHOLD;

printf(
    "[%s] passes in last %d min: %d (threshold %d) -> %s\n",
    date('Y-m-d H:i:s'),
    WINDOW_MINUTES,
    $count,
    ALERT_THRESHOLD,
    $overThreshold ? ($dryRun ? 'WOULD ALERT (dry run)' : 'ALERTING') : 'ok'
);

if (!$overThreshold || $dryRun) {
    exit(0);
}

$subject = sprintf('[BoardingPass] %d passes in the last hour', $count);
$body = sprintf(
    "%d boarding passes were generated in the last %d minutes (alert threshold is %d).\n\n"
        . "Server time: %s\n",
    $count,
    WINDOW_MINUTES,
    ALERT_THRESHOLD,
    date('Y-m-d H:i:s')
);
$headers = implode("\r\n", [
    'From: passRateAlert@shaffex.com',
    'Content-Type: text/plain; charset=utf-8',
]);

if (!mail(ALERT_EMAIL, $subject, $body, $headers)) {
    fwrite(STDERR, sprintf("[%s] passRateAlert ERROR: mail() failed for %s\n", date('Y-m-d H:i:s'), ALERT_EMAIL));
    exit(1);
}
