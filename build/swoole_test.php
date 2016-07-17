<?php
$table = new swoole_table(1024);
$table->column('id', swoole_table::TYPE_INT, 4);       //1,2,4,8
$table->column('name', swoole_table::TYPE_STRING, 64);
$table->column('num', swoole_table::TYPE_FLOAT);
$table->create();

$data = ['id' => 1, 'name' => 'cui', 'num' => 4];
$table->set('a', $data);
//echo $table->count() . PHP_EOL;
$data['num'] = 1234;
$table->set('b', $data);
$data['num']  = 10;
$data['name'] = 'han';
$table->set('c', $data);
//echo $table->count() . PHP_EOL;
//var_dump($table->count());
$flag = 1;
foreach ($table as $key => $row)
{
    $flag = 0;
    //echo $key . "\t" . $row['id'] . "\t" . $row['name'] . "\t" . $row['num'] . PHP_EOL;
    break;
}
exit($flag);
