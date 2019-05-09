<?php
class A {
    function __construct () {
        $this->b = new B($this);
    }
}

class B {
    function __construct ($parent = NULL) {
        $this->parent = $parent;
    }
}
$baseMemory = memory_get_usage();
$is_match = 0;
$total  = 0;
$max    = 0;
$lock   = false;
$lock_num = 0;
for ($i = 0 ; $i < 1000000 ; $i++) {
    $a = new A();
    unset($a);
    if ( $i % 500 === 0 )
    {
        $mem = memory_get_usage();
        if ($lock === false || $lock_num < 3) {
            if ($mem >= $max) {
                $max   = $mem;
                $total = 0;

                if ($lock) {
                    $lock_num++;
                }
                continue;
            } else {
                $lock = true;
            }
        }
        if ($mem === $max) {
            if (++$is_match >= 10) {
                //echo '匹配了' . PHP_EOL;
                exit(0);
            }
            $total = 0;
        } elseif ($mem > $max) {
            $total++;
            if ($total > 10) {
                /*
                echo 'mem:    ' . $mem . PHP_EOL;
                echo 'max:    ' . $max . PHP_EOL;
                echo '存在内存溢出' . PHP_EOL;
                */
                exit(1);
            }
        }
        //gc_collect_cycles();
        //echo sprintf( '%8d: ', $i ), $mem - $baseMemory, "\n";
    }
}
