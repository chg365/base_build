<?php
//var_export(spl_classes());
//exit;
define('DS', '/');
define('PHP_LIB_DIR', '/usr/local/chg/base/inc');
define('PHP_INC_DIR', '/usr/local/chg/base/inc');
define('GEOIP_DEFAULT_COUNTRY_ISO_CODE', 'CN');
// {{{ function base_autoload($classname) 在试图使用尚未被定义的类时自动调用
/**
 * 程序在试图使用尚未被定义的类时自动调用
 * 类文件存放规则:在LIB_DIR目录下,子命名空间为目录,类名为文件名,以.class.php为后缀的文件
 *
 * @param $classname string 类名
 * @return void
 */
function base_autoload($classname)
{
    $classname = ltrim($classname, '\\');
    $file      = NULL;

    if (FALSE !== strpos($classname, '\\') && strpos($classname, 'chg\\base') !== FALSE)
    {
        //--类都是以.class.php为后缀的
        $classname .= '.class.php';
        $tmp_arr = explode('\\', $classname);
        if ('chg' === $tmp_arr[0] && $tmp_arr[1] === 'base' && $tmp_arr[2])
        {
            unset($tmp_arr[0], $tmp_arr[1]);
        }
        $classname  = implode(DS, $tmp_arr);
        $file       = PHP_LIB_DIR . DS . $classname;
    }
    elseif (FALSE !== strpos($classname, '\\'))
    {
        $file = PHP_INC_DIR . DS . str_replace('\\', '/', trim($classname, '\\')) . '.php';
        //$arr = explode('\\', $classname);
    }
    /*
    elseif (substr($classname, 0, 4) === 'Zend')
    {
        //$file = ZEND_DIR . DS . str_replace('_', DS, $classname) . '.php';
        ;
    }
    */

    if ($file && is_file($file))
    {
        require_once($file);
    }
}
// }}}
spl_autoload_register('base_autoload');



use GeoIp2\Database\Reader;

define('GEOIP2_MMDB_DIR', '/usr/local/chg/base/etc/geoip');
$ip_arr = array(
        '118.194.236.35', // 北京
        '61.128.115.110',
        '206.220.42.25',
        '107.191.107.47',
        '61.128.101.32',
        '112.225.35.70', // 山东省青岛市
        '115.29.113.101', // 浙江省杭州市
        '112.124.127.64', // 浙江省杭州市
        '180.153.214.152', // 上海市
        );
foreach (array('City'/*, 'Country'*/) as $type) {
    $locales = array('zh-CN', 'en');
    $reader = new Reader(GEOIP2_MMDB_DIR . '/GeoLite2-' . $type . '.mmdb', $locales);
    $method = lcfirst($type);

    foreach ($ip_arr as $ip)
    {
        $record = $reader->$method($ip);
        //var_export($record);
        $str = '';
        if ($record->country->isoCode == GEOIP_DEFAULT_COUNTRY_ISO_CODE)
        {
            $str = $record->subdivisions[0]->name . ' ' . $record->city->name;
        }
        else
        {
            $str = /*$record->continent->name . ' ' . */$record->country->name . ' ' . $record->subdivisions[0]->name . ' ' . $record->city->name;

        }
        echo 'IP: ' . $ip . "\t" . '来自: ' . $str . PHP_EOL;
        //$record->continent->name . ' ' . $record->country->name . ' ' . $record->subdivisions[0]->name . ' ' . $record->city->name . ' ' . $record->country->isoCode .  PHP_EOL;
        //echo $record->subdivisions[0]->name . PHP_EOL;
        //echo $record->continent->name . PHP_EOL;
        //echo $record->country->isoCode . PHP_EOL;
    }
    exit;
}
$reader->close();

