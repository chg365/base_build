<?php
/**
 * PHP常量定义和一些其它配置
 */

error_reporting(E_ALL);

//--目录分隔符
define('DS', DIRECTORY_SEPARATOR);
// {{{ 目录定义
define('BASE_DIR', '/usr/local/chg/base');
    define('BIN_DIR', BASE_DIR . DS . 'bin');
    define('CONF_DIR', BASE_DIR . DS . 'conf');
    define('CONTRIB_DIR', BASE_DIR . DS . 'contrib');
        define('CONTRIB_LIB_DIR', CONTRIB_DIR . DS . 'lib');
    define('ETC_DIR', BASE_DIR . DS . 'etc');
    define('DATA_DIR', BASE_DIR . DS . 'data');
        define('CACHE_DIR', DATA_DIR . DS . 'cache');
            define('PHP_CACHE_DIR', CACHE_DIR . DS . 'php');
        define('SQLITE_DATA_DIR', DATA_DIR . DS . 'sqlite3');
    define('INC_DIR', BASE_DIR . DS . 'inc');
    define('LIB_DIR', BASE_DIR . DS . 'lib');
        define('PHP_LIB_DIR', LIB_DIR . DS . 'php');
    define('LOG_DIR', BASE_DIR . DS . 'log');
    define('OPT_DIR', BASE_DIR . DS . 'opt');
    define('RUN_DIR', BASE_DIR . DS . 'run');
        define('MYSQL_RUN_DIR', RUN_DIR . DS . 'mysql');
    define('SBIN_DIR', BASE_DIR . DS . 'sbin');
// }}}

define('ITSELF_NAMESPACE', 'chg\base');

define('CRON_EXECUTOR', 'nobody'); //--

define('DATABASE_TYPE', 'sqlite'); //mysql
//--mysql
define('MYSQL_HOST', 'localhost');
define('MYSQL_PORT', '3306');
define('MYSQL_USER', 'root');
define('MYSQL_PASS', 'chg365');
define('MYSQL_DB_NAME', 'chg_base');
define('MYSQL_SOCK', MYSQL_RUN_DIR . DS . 'mysql.sock');

define('NODE_ID', null); // 可以配置每台服务器不同 null 或 0 至  (NODE_NUM - 1 )
define('NODE_NUM', 5); // NODE_ID个数, 系统运行后，不可更改, 数值不可大于9
define('DEVICE_NUM', 5); // 当前NODE_ID下可以有的DEVICE_ID个数

// swoole 服务器端
define('SWOOLE_SERVER_HOST', '0.0.0.0');   // 服务对外提供服务的监听地址
define('SWOOLE_SERVER_PORT', '9501');      // 服务对外提供服务的监听端口
define('SWOOLE_MANAGE_HOST', '127.0.0.1'); // 服务管理监听地址
define('SWOOLE_MANAGE_PORT', 9502);        // 服务管理监听端口
define('SWOOLE_WORKER_USER', 'nobody'); // 这里要与php-fpm、nginx的执行用户一致
define('SWOOLE_WORKER_GROUP', 'nobody'); //这里要与php-fpm、nginx的执行用户组一致
// swoole 客户端
define('SWOOLE_REMOTE_HOST', '127.0.0.1');   // 客户端访问的地址
define('SWOOLE_REMOTE_PORT', '9501');      // 客户端访问的端口

define('CLEAN_CACHE_DATA_TIME', '60'); // 清理多少天以前的数据

require_once(INC_DIR . DS . 'function.php');

/*
// debug
use \chg\base\type\debug\debug_level;
// DEBUG_NOTICE DEBUG_WARNING DEBUG_ERROR DEBUG_DEBUG DEBUG_ALL
$debug_level = debug_level::DEBUG_ERROR | debug_level::DEBUG_WARNING;
define('DEBUG_LEVEL', $debug_level);

use \chg\base\type\debug\debug_types;
$debug_type = debug_types::DEBUG_LOG;
define('DEBUG_TYPE', $debug_type);
unset($debug_level, $debug_type);
*/

spl_autoload_register('autoload_global');
$log_file = LOG_DIR . DS . 'shutdown.log';
if (!is_file($log_file))
{
    touch($log_file);
    exec('chmod a+w ' . $log_file);
}
unset($log_file);

if (PHP_SAPI === 'cli')
{
    $error_log = ini_get('error_log');
    if (strpos($error_log, LOG_DIR) === 0 && !is_file($error_log)) {
        touch($error_log);
        exec('chmod a+x' . $error_log);
    }
    unset($error_log);
}

register_shutdown_function('shutdown_global');
