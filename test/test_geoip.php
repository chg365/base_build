<?php

geoip_setup_custom_directory('/usr/local/chg/base/etc/geoip');
/*
$arr = array(
        GEOIP_COUNTRY_EDITION,
        GEOIP_REGION_EDITION_REV0,
        GEOIP_CITY_EDITION_REV0,
        GEOIP_ORG_EDITION,
        GEOIP_ISP_EDITION,
        GEOIP_CITY_EDITION_REV1,
        GEOIP_REGION_EDITION_REV1,
        GEOIP_PROXY_EDITION,
        GEOIP_ASNUM_EDITION,
        GEOIP_NETSPEED_EDITION,
        GEOIP_DOMAIN_EDITION,
       );
foreach ($arr as $k => $v)
{
    echo geoip_database_info(GEOIP_COUNTRY_EDITION) . PHP_EOL;
}
foreach (geoip_db_get_all_info() as $k => $v)
{
    if ($v['available'])
    echo $v['filename'] . "\t" . ((int)($v['available'])) . "\t" . $v['description'] . PHP_EOL;
}
*/
//var_dump(geoip_continent_code_by_name('www.biantianya.com'));
//var_dump(geoip_country_code_by_name('www.eyou.net'));
//var_dump(geoip_country_code3_by_name('www.biantianya.com'));
//var_dump(geoip_country_name_by_name('www.eyou.net'));

//var_dump(geoip_db_avail(GEOIP_COUNTRY_EDITION));
//var_dump(geoip_db_avail(GEOIP_ASNUM_EDITION));
//var_dump(geoip_db_filename(GEOIP_COUNTRY_EDITION));
if (geoip_db_avail(GEOIP_ORG_EDITION))
{
    echo geoip_org_by_name('www.eyou.net') . PHP_EOL;
}
if (geoip_db_avail(GEOIP_NETSPEED_EDITION))
{
    var_dump(geoip_id_by_name('www.eyou.net'));
}
if (geoip_db_avail(GEOIP_ISP_EDITION))
var_dump(geoip_isp_by_name('www.eyou.net'));
//var_dump(geoip_record_by_name('www.eyou.net'));
//var_dump(geoip_region_by_name('www.eyou.net'));
var_dump(geoip_region_name_by_code('CN', '03'));
var_dump(geoip_country_code_by_addr('117.79.226.69'));
var_dump(geoip_country_code3_by_addr('11.27.35.121'));
var_dump(geoip_time_zone_by_country_and_region('CN', '23'));
