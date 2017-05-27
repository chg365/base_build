<?php
error_reporting(E_ALL);
define('DS', '/');
define('PHP_LIB_DIR', '/usr/local/chg/base/inc');
define('PHP_INC_DIR', '/usr/local/chg/base/inc');
define('GEOIP_DEFAULT_COUNTRY_ISO_CODE', 'CN');
// {{{ function chg_autoload($classname) 在试图使用尚未被定义的类时自动调用
/**
 * 程序在试图使用尚未被定义的类时自动调用
 * 类文件存放规则:在LIB_DIR目录下,子命名空间为目录,类名为文件名,以.class.php为后缀的文件
 *
 * @param $classname string 类名
 * @return void
 */

function chg_autoload($classname)
{
    $classname = ltrim($classname, '\\');
    echo $classname . PHP_EOL;
    $file      = NULL;

    if (FALSE !== strpos($classname, '\\') && strpos($classname, 'chg\\base') !== FALSE)
    {
        //--类都是以.class.php为后缀的
        $classname .= '.class.php';
        $tmp_arr = explode('\\', $classname);
        if ('chg' === $tmp_arr[0] && $tmp_arr[1] === 'office' && $tmp_arr[2])
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

    var_dump($file);
    if ($file && is_file($file))
    {
        require_once($file);
    }
}
// }}}
spl_autoload_register('chg_autoload');
/*
*/
var_dump(spl_autoload_functions());

define('GEOIP2_MMDB_DIR', '/usr/local/chg/base/etc/geoip2');
$ip_arr = array(
        '215.3.234.5',
        '127.0.0.1',
        '172.16.100.254',
        '10.13.14.243',
        '47.93.81.7',
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
    $locales = array('zh-CN'/*, 'en'*/);
    $file = GEOIP2_MMDB_DIR . '/GeoLite2-' . $type . '.mmdb';
    if (!is_file($file))
    {
        echo $file . '  not exists' . PHP_EOL;
        continue;
    }
    $reader = new \GeoIp2\Database\Reader($file, $locales);
    $method = lcfirst($type);

    foreach ($ip_arr as $ip)
    {
        try {
            $record = $reader->$method($ip);
        }
        catch (\exception $e)
        {
            echo $e->getCode() . PHP_EOL;
            echo $e->getMessage() . PHP_EOL;
            continue;
        }
        //var_export($record);
        $str = '';
        if (strtolower($type) == 'city')
        {
        if ($record->country->isoCode == GEOIP_DEFAULT_COUNTRY_ISO_CODE)
        {
            $str = $record->subdivisions[0]->name . ' ' . $record->city->name;
        }
        else
        {
            $str = /*$record->continent->name . ' ' . */$record->country->name . ' '
                 . $record->subdivisions[0]->name . ' ' . $record->city->name;

        }
        echo 'IP: ' . $ip . "\t" . '来自: ' . $str . PHP_EOL;
        print($record->country->isoCode . "\n"); // 'US' 
        print($record->country->name . "\n"); // 'United States'
        //var_dump($record->country->names);
        //var_dump($record->city);
        print($record->country->names['zh-CN'] . "\n"); // '美国'

        print($record->mostSpecificSubdivision->name . "\n"); // 'Minnesota' 北京市
        print($record->mostSpecificSubdivision->isoCode . "\n"); // 'MN' 11 
        //var_dump($record);

        print($record->city->name . "\n"); // 'Minneapolis'

        print($record->postal->code . "\n"); // '55455' 邮政编码 空

        print($record->location->latitude . "\n"); // 44.9733 纬度
        print($record->location->longitude . "\n"); // -93.2323 经度
//        var_dump(get_included_files());
        //$record->continent->name . ' ' . $record->country->name . ' ' . $record->subdivisions[0]->name . ' ' . $record->city->name . ' ' . $record->country->isoCode .  PHP_EOL;
        //echo $record->subdivisions[0]->name . PHP_EOL;
        //echo $record->continent->name . PHP_EOL;
        //echo $record->country->isoCode . PHP_EOL;
        }
        elseif (strtolower($type) == 'country')
        {
            var_dump($record->continent);
        }
        else
        {
            var_dump($record);
        }
    }
    $reader->close();
}

