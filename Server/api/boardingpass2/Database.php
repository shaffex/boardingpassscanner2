<?php
declare(strict_types=1);

const DB_HOST = 'localhost';
const DB_PORT = '3306';
const DB_NAME = 'u206734641_bpscanner2';
const DB_USER = 'u206734641_bps2_user';
const DB_PASS = 'XOH5z^3hZq1=';
const DB_TABLE = 'boardingPasses';
const DB_DEBUG = false;
const DB_DEBUG_LOG = __DIR__ . '/dbLog.txt';

/**
 * Small database helper.
 *
 * CLI test:
 *   php Database.php test
 *
 * Browser test:
 *   Database.php?test=1
 */
final class Database
{
    private PDO $pdo;
    private string $table;

    public function __construct()
    {
        $this->table = $this->safeTableName(DB_TABLE);
        $this->connectToMysql();

        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $this->pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        $this->createTables();
    }

    public function add(string $type, string $text, int $year): int
    {
        $type = trim($type);
        $text = trim($text);

        if ($type === '') {
            throw new InvalidArgumentException('type cannot be empty');
        }

        if ($text === '') {
            throw new InvalidArgumentException('text cannot be empty');
        }

        if ($year < 1900 || $year > 3000) {
            throw new InvalidArgumentException('year must be between 1900 and 3000');
        }

        $stmt = $this->pdo->prepare(
            "INSERT INTO {$this->table} (type, text, year, ip) VALUES (:type, :text, :year, :ip)"
        );
        $stmt->execute([
            ':type' => $type,
            ':text' => $text,
            ':year' => $year,
            ':ip' => $this->requestIp(),
        ]);

        $id = (int)$this->pdo->lastInsertId();
        $this->debugLog("insert ok id={$id} type={$type} year={$year}");

        return $id;
    }

    public function find(int $id): ?array
    {
        $stmt = $this->pdo->prepare("SELECT * FROM {$this->table} WHERE id = :id");
        $stmt->execute([':id' => $id]);

        $row = $stmt->fetch();
        return $row === false ? null : $row;
    }

    public function all(): array
    {
        $stmt = $this->pdo->query("SELECT * FROM {$this->table} ORDER BY id DESC");
        return $stmt->fetchAll();
    }

    public function count(): int
    {
        return (int)$this->pdo->query("SELECT COUNT(*) FROM {$this->table}")->fetchColumn();
    }

    private function connectToMysql(): void
    {
        if (DB_HOST === '' || DB_NAME === '' || DB_USER === '') {
            throw new RuntimeException('DB_HOST, DB_NAME, and DB_USER must be set in Database.php');
        }

        $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=utf8mb4';
        $this->pdo = new PDO($dsn, DB_USER, DB_PASS);
        $this->debugLog('connected to mysql host=' . DB_HOST . ' db=' . DB_NAME);
    }

    private function createTables(): void
    {
        $this->pdo->exec(
            "CREATE TABLE IF NOT EXISTS {$this->table} (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                type VARCHAR(100) NOT NULL,
                text TEXT NOT NULL,
                year INT NOT NULL,
                ip VARCHAR(45) NOT NULL,
                created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );

        $this->addColumnIfMissing('ip', "VARCHAR(45) NOT NULL DEFAULT '' AFTER year");
        $this->addColumnIfMissing('created', 'TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER ip');
        $this->moveCreatedToEnd();
    }

    private function addColumnIfMissing(string $column, string $definition): void
    {
        $stmt = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = :database
               AND TABLE_NAME = :table
               AND COLUMN_NAME = :column'
        );
        $stmt->execute([
            ':database' => DB_NAME,
            ':table' => $this->table,
            ':column' => $column,
        ]);

        if ((int)$stmt->fetchColumn() === 0) {
            $this->pdo->exec("ALTER TABLE {$this->table} ADD COLUMN {$column} {$definition}");
            $this->debugLog("added column {$column}");
        }
    }

    private function moveCreatedToEnd(): void
    {
        try {
            $this->pdo->exec(
                "ALTER TABLE {$this->table}
                 MODIFY COLUMN created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER ip"
            );
            $this->debugLog('moved created column after ip');
        } catch (Throwable $e) {
            self::logFailure($e);
        }
    }

    public static function logFailure(Throwable $e): void
    {
        self::writeDebugLog('failure: ' . $e->getMessage());
    }

    private function debugLog(string $message): void
    {
        self::writeDebugLog($message);
    }

    private static function writeDebugLog(string $message): void
    {
        if (!DB_DEBUG) return;

        $line = sprintf("[%s] %s\n", date('Y-m-d H:i:s'), $message);
        @file_put_contents(DB_DEBUG_LOG, $line, FILE_APPEND | LOCK_EX);
    }

    private function requestIp(): string
    {
        $ip = $_SERVER['HTTP_CF_CONNECTING_IP']
            ?? $_SERVER['HTTP_X_FORWARDED_FOR']
            ?? $_SERVER['REMOTE_ADDR']
            ?? 'cli';

        if (str_contains($ip, ',')) {
            $ip = trim(explode(',', $ip)[0]);
        }

        return substr($ip, 0, 45);
    }

    private function safeTableName(string $table): string
    {
        if (!preg_match('/^[A-Za-z_][A-Za-z0-9_]*$/', $table)) {
            throw new InvalidArgumentException('Invalid DB_TABLE name');
        }

        return $table;
    }
}

function testDatabase(): array
{
    $database = new Database();
    $id = $database->add('test', 'Database test entry', (int)date('Y'));
    $entry = $database->find($id);

    return [
        'ok' => $entry !== null,
        'insertedId' => $id,
        'entry' => $entry,
        'totalRows' => $database->count(),
    ];
}

if (PHP_SAPI === 'cli' && basename(__FILE__) === basename($_SERVER['SCRIPT_FILENAME'] ?? '')) {
    if (($argv[1] ?? '') !== 'test') {
        echo "Usage: php Database.php test\n";
        exit(0);
    }

    echo json_encode(testDatabase(), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;
}

if (PHP_SAPI !== 'cli' && isset($_GET['test'])) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(testDatabase(), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
}
