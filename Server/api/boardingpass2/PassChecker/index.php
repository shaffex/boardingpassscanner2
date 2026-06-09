<?php
declare(strict_types=1);

/**
 * PassChecker — minimal admin website to verify generated .pkpass files.
 *
 * Scans the GeneratedPasses directory, opens each .pkpass (a ZIP containing
 * pass.json) and reports issues — e.g. a missing relevantDate, missing
 * organizationName, or missing barcode. The organization name is shown for
 * every pass.
 *
 * Protected by a simple session password. CHANGE ADMIN_PASSWORD before use.
 */

const ADMIN_PASSWORD     = 'kokoce';
const GENERATED_PASSES_DIR = __DIR__ . '/../GeneratedPasses';
const MAX_PASSES         = 500;   // newest N passes to scan; override with ?max=N

// ---------------------------------------------------------------------------
// AUTH (session password gate)
// ---------------------------------------------------------------------------
session_start();

if (isset($_GET['logout'])) {
    $_SESSION = [];
    session_destroy();
    header('Location: ' . strtok($_SERVER['REQUEST_URI'], '?'));
    exit;
}

if (!empty($_POST['password'])) {
    if (hash_equals(ADMIN_PASSWORD, (string)$_POST['password'])) {
        $_SESSION['auth'] = true;
    } else {
        $loginError = 'Wrong password.';
    }
}

if (empty($_SESSION['auth'])) {
    renderLogin($loginError ?? null);
    exit;
}

// Detail view for a single pass (semantics fields).
if (!empty($_GET['pass'])) {
    renderDetail((string)$_GET['pass']);
    exit;
}

// ---------------------------------------------------------------------------
// READ & VERIFY PASSES
// ---------------------------------------------------------------------------

/** Read and decode pass.json out of a .pkpass (ZIP) file. */
function readPassJson(string $path): ?array {
    if (!class_exists('ZipArchive')) return null;
    $zip = new ZipArchive();
    if ($zip->open($path) !== true) return null;
    $raw = $zip->getFromName('pass.json');
    $zip->close();
    if ($raw === false) return null;
    $json = json_decode($raw, true);
    return is_array($json) ? $json : null;
}

/** Return a list of human-readable issues for one pass (empty = ok). */
function passIssues(?array $p): array {
    if ($p === null) {
        return ['Cannot read pass.json'];
    }

    $issues = [];

    if (empty($p['relevantDate'])) {
        $issues[] = 'No relevant date';
    }
    if (empty($p['organizationName'])) {
        $issues[] = 'No organization name';
    }

    $hasBarcode = !empty($p['barcode']['message']) || !empty($p['barcodes'][0]['message']);
    if (!$hasBarcode) {
        $issues[] = 'No barcode';
    }
    if (empty($p['boardingPass'])) {
        $issues[] = 'No boardingPass section';
    }

    return $issues;
}

/** semantic vs generic, for display. */
function passKind(array $p): string {
    return !empty($p['semantics']) ? 'semantic' : 'generic';
}

/** A field (value + label) by key within a boardingPass section, or ['', '']. */
function field(array $p, string $section, string $key): array {
    foreach ($p['boardingPass'][$section] ?? [] as $f) {
        if (is_array($f) && ($f['key'] ?? '') === $key) {
            return [(string)($f['value'] ?? ''), (string)($f['label'] ?? '')];
        }
    }
    return ['', ''];
}

/** Convenience: just the value of a field by key. */
function fieldValue(array $p, string $section, string $key): string {
    return field($p, $section, $key)[0];
}

$dir   = realpath(GENERATED_PASSES_DIR);
$files = ($dir !== false) ? glob($dir . '/*.pkpass') : [];
if ($files === false) $files = [];
rsort($files); // newest first (filenames are timestamp-based)

$totalFiles = count($files);
$maxPasses  = isset($_GET['max']) ? max(1, (int)$_GET['max']) : MAX_PASSES;
$files      = array_slice($files, 0, $maxPasses);

$rows         = [];
$issueCount   = 0;
foreach ($files as $path) {
    $pass   = readPassJson($path);
    $issues = passIssues($pass);
    if ($issues) $issueCount++;

    $rows[] = [
        'file'      => basename($path),
        'org'       => $pass['organizationName'] ?? '',
        'passenger' => $pass ? fieldValue($pass, 'secondaryFields', 'passenger') : '',
        'from'      => $pass ? field($pass, 'primaryFields', 'from') : ['', ''],
        'to'        => $pass ? field($pass, 'primaryFields', 'to')   : ['', ''],
        'kind'      => $pass ? passKind($pass) : '—',
        'relevant'  => $pass['relevantDate'] ?? '',
        'issues'    => $issues,
    ];
}

// ---------------------------------------------------------------------------
// RENDER
// ---------------------------------------------------------------------------
function h(string $s): string {
    return htmlspecialchars($s, ENT_QUOTES, 'UTF-8');
}

/** Recursively render a semantics value as nested rows. */
function renderSemanticRows($value, int $depth = 0): string {
    $pad = $depth * 18;
    $out = '';
    if (is_array($value)) {
        // List of items (e.g. seats) vs associative map.
        $isList = array_keys($value) === range(0, count($value) - 1);
        foreach ($value as $k => $v) {
            $label = $isList ? ('[' . $k . ']') : (string)$k;
            if (is_array($v) && $v !== []) {
                $out .= '<tr><td class="k" style="padding-left:' . (12 + $pad) . 'px"><b>' . h($label) . '</b></td><td></td></tr>';
                $out .= renderSemanticRows($v, $depth + 1);
            } elseif (is_array($v)) {
                // Empty array/object (e.g. seats:[[]] when the barcode had no seat).
                $out .= '<tr><td class="k" style="padding-left:' . (12 + $pad) . 'px">' . h($label) . '</td>'
                      . '<td class="muted">(empty)</td></tr>';
            } else {
                $val = is_bool($v) ? ($v ? 'true' : 'false') : (string)$v;
                $out .= '<tr><td class="k" style="padding-left:' . (12 + $pad) . 'px">' . h($label) . '</td>'
                      . '<td class="mono">' . ($val === '' ? '<span class="muted">(empty)</span>' : h($val)) . '</td></tr>';
            }
        }
    } else {
        $val = is_bool($value) ? ($value ? 'true' : 'false') : (string)$value;
        $out .= '<tr><td></td><td class="mono">' . h($val) . '</td></tr>';
    }
    return $out;
}

/** Detail page: shows the semantics fields of a single pass. */
function renderDetail(string $requested): void {
    $dir  = realpath(GENERATED_PASSES_DIR);
    $name = basename($requested);
    $path = $dir !== false ? $dir . '/' . $name : '';

    $valid = $dir !== false
        && $path !== ''
        && str_ends_with(strtolower($name), '.pkpass')
        && is_file($path)
        && strpos(realpath($path) ?: '', $dir) === 0;

    $pass       = $valid ? readPassJson($path) : null;
    $semantics  = $pass['semantics'] ?? null;
    ?><!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PassChecker — <?= h($name) ?></title>
<style>
  body{font-family:system-ui,sans-serif;background:#0e1116;color:#e6edf3;margin:0;padding:1.5rem}
  a{color:#58a6ff;text-decoration:none}
  h1{font-size:1.1rem;margin:.2rem 0 .2rem}
  .sub{color:#8b949e;font-size:.85rem;margin-bottom:1.2rem}
  table{border-collapse:collapse;width:100%;max-width:680px;font-size:.85rem}
  td{padding:.4rem .6rem;border-bottom:1px solid #21262d;vertical-align:top}
  td.k{color:#8b949e;width:40%}
  .mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  .muted{color:#6e7681}
  .issue{color:#ff7b72}
</style></head><body>
  <p><a href="<?= h(strtok($_SERVER['REQUEST_URI'], '?')) ?>">&larr; Back to all passes</a></p>
  <h1><?= h($pass['organizationName'] ?? $name) ?></h1>
  <div class="sub mono"><?= h($name) ?></div>

  <?php if (!$valid || $pass === null): ?>
    <p class="issue">Pass not found or unreadable.</p>
  <?php elseif (empty($semantics)): ?>
    <p class="issue">This pass has no <span class="mono">semantics</span> section (generic pass).</p>
  <?php else: ?>
    <table><tbody>
      <?= renderSemanticRows($semantics) ?>
    </tbody></table>
  <?php endif; ?>
</body></html><?php
}

function renderLogin(?string $error): void {
    ?><!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PassChecker — login</title>
<style>
  body{font-family:system-ui,sans-serif;background:#0e1116;color:#e6edf3;display:flex;
       min-height:100vh;align-items:center;justify-content:center;margin:0}
  form{background:#161b22;padding:2rem;border-radius:12px;border:1px solid #30363d;width:280px}
  h1{font-size:1.1rem;margin:0 0 1rem}
  input{width:100%;box-sizing:border-box;padding:.6rem;margin-bottom:.8rem;border-radius:8px;
        border:1px solid #30363d;background:#0d1117;color:#e6edf3}
  button{width:100%;padding:.6rem;border:0;border-radius:8px;background:#238636;color:#fff;
         font-weight:600;cursor:pointer}
  .err{color:#ff7b72;font-size:.85rem;margin-bottom:.6rem}
</style></head><body>
  <form method="post">
    <h1>PassChecker</h1>
    <?php if ($error): ?><div class="err"><?= h($error) ?></div><?php endif; ?>
    <input type="password" name="password" placeholder="Admin password" autofocus>
    <button type="submit">Sign in</button>
  </form>
</body></html><?php
}
?><!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PassChecker</title>
<style>
  body{font-family:system-ui,sans-serif;background:#0e1116;color:#e6edf3;margin:0;padding:1.5rem}
  header{display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem}
  h1{font-size:1.25rem;margin:0}
  .summary{color:#8b949e;font-size:.9rem;margin-bottom:1rem}
  .summary b{color:#e6edf3}
  a.logout{color:#8b949e;font-size:.85rem;text-decoration:none}
  table{border-collapse:collapse;width:100%;font-size:.85rem}
  th,td{text-align:left;padding:.5rem .6rem;border-bottom:1px solid #21262d;vertical-align:top}
  th{color:#8b949e;font-weight:600;position:sticky;top:0;background:#0e1116}
  tr.bad{background:rgba(248,81,73,.08)}
  .ok{color:#3fb950}
  .issue{color:#ff7b72}
  .kind{display:inline-block;padding:.05rem .45rem;border-radius:6px;font-size:.72rem;
        border:1px solid #30363d;color:#8b949e}
  a.kind-link{text-decoration:none;color:#58a6ff;border-color:#1f6feb}
  a.kind-link:hover{background:rgba(56,139,253,.12)}
  .mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  .muted{color:#6e7681}
</style></head><body>
  <header>
    <h1>PassChecker</h1>
    <a class="logout" href="?logout=1">Log out</a>
  </header>

  <?php if ($dir === false): ?>
    <div class="summary issue">GeneratedPasses directory not found at
      <span class="mono"><?= h(GENERATED_PASSES_DIR) ?></span></div>
  <?php else: ?>
    <div class="summary">
      Scanned <b><?= count($rows) ?></b> of <b><?= $totalFiles ?></b> pass<?= $totalFiles === 1 ? '' : 'es' ?> in
      <span class="mono"><?= h($dir) ?></span> —
      <b class="<?= $issueCount ? 'issue' : 'ok' ?>"><?= $issueCount ?></b> with issues.
      <?php if ($totalFiles > count($rows)): ?>
        <span class="muted">(showing newest <?= count($rows) ?>; use <span class="mono">?max=N</span> for more)</span>
      <?php endif; ?>
    </div>

    <table>
      <thead>
        <tr>
          <th>File</th>
          <th>Organization name</th>
          <th>Passenger</th>
          <th>Route</th>
          <th>Type</th>
          <th>Relevant date</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($rows as $r): ?>
          <tr class="<?= $r['issues'] ? 'bad' : '' ?>">
            <td class="mono"><?= h($r['file']) ?></td>
            <td><?= $r['org'] !== '' ? h($r['org']) : '<span class="issue">(none)</span>' ?></td>
            <td><?= $r['passenger'] !== '' ? h($r['passenger']) : '<span class="muted">—</span>' ?></td>
            <td>
              <?php
                [$fc, $fl] = $r['from'];
                [$tc, $tl] = $r['to'];
                if ($fc !== '' || $tc !== '' || $fl !== '' || $tl !== ''):
              ?>
                <span class="mono"><?= h($fc !== '' ? $fc : '?') ?></span><?php if ($fl !== ''): ?> <span class="muted"><?= h($fl) ?></span><?php endif; ?>
                &rarr;
                <span class="mono"><?= h($tc !== '' ? $tc : '?') ?></span><?php if ($tl !== ''): ?> <span class="muted"><?= h($tl) ?></span><?php endif; ?>
              <?php else: ?>
                <span class="muted">—</span>
              <?php endif; ?>
            </td>
            <td>
              <?php if ($r['kind'] === 'semantic'): ?>
                <a class="kind kind-link" href="?pass=<?= h(urlencode($r['file'])) ?>"><?= h($r['kind']) ?> &rsaquo;</a>
              <?php else: ?>
                <span class="kind"><?= h($r['kind']) ?></span>
              <?php endif; ?>
            </td>
            <td class="mono <?= $r['relevant'] === '' ? 'muted' : '' ?>">
              <?= $r['relevant'] !== '' ? h($r['relevant']) : '—' ?>
            </td>
            <td>
              <?php if (!$r['issues']): ?>
                <span class="ok">✓ OK</span>
              <?php else: ?>
                <span class="issue"><?= h(implode(', ', $r['issues'])) ?></span>
              <?php endif; ?>
            </td>
          </tr>
        <?php endforeach; ?>
        <?php if (!$rows): ?>
          <tr><td colspan="7" class="muted">No .pkpass files found.</td></tr>
        <?php endif; ?>
      </tbody>
    </table>
  <?php endif; ?>
</body></html>
