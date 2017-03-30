<?php

class memory_table
{
    // {{{ const
    const MEMORY_TABLE_MAX_SIZE = 4096; // 必须为2的指数
    const MEMORY_TABLE_MIN_SIZE = 128; // 必须为2的指数
    const MEMORY_TYPE_INT = \swoole_table::TYPE_INT;
    const MEMORY_TYPE_FLOAT = \swoole_table::TYPE_FLOAT;
    const MEMORY_TYPE_STRING = \swoole_table::TYPE_STRING;

    const MEMORY_LENGTH_TINYINT  = 1; //  -128 127
    const MEMORY_LENGTH_SMALLINT = 2; // -32768 32767
    const MEMORY_LENGTH_INT      = 4; // -2147483648 2147483647
    const MEMORY_LENGTH_BIGINT   = 8; // -9223372036854775808 9223372036854775807
    // }}}
    // {{{ memeber
    /**
     * 内存大小 swoole_memory_table使用的最大行数
     *
     * @var int
     */
    private $__size = 0;

    /**
     * 定义swoole内存表的字段信息
     *
     * @var array
     */
    private $__field_arr = array();
    /**
     * swoole内存表字段数目
     *
     * @var int
     */
    private $__field_num = 0;

    /**
     * \swoole_table对象
     *
     * @var \swoole_table
     */
    protected $__table = null;

    /**
     * \swoole_lock对象
     *
     * @var \swoole_lock
     */
    protected $__lock  = null;
    /**
     * 是否使用锁(swoole_table是内置行锁自选锁，一般不需要额外的锁)
     *
     * @var boolean
     */
    protected $__used_lock = false;
    // }}}

    // {{{ public function __construct(array $field_array, int $max_rows_num, $used_lock = false)
    /**
     * 构造函数
     *
     * @param array $field_array 用于创建\swoole_table内存表的字段信息数组
     * @param int $max_rows_num 最大行数
     * @param boolean $used_lock 是否使用额外的锁(\swoole_lock)
     *
     * @return void
     */

    public function __construct(array $field_array, int $max_rows_num, $used_lock = false)
    {
        $this->__size      = $this->init_memory_table_size($max_rows_num);
        $this->__field_arr = $this->filter_field_array($field_array);
        $this->__field_num = count($this->__field_arr);
        $this->__used_lock = (boolean) $used_lock;
        $this->create_table();
        if ($this->__used_lock)
        {
            $this->create_lock();
        }
    }
    // }}}
    // {{{ protected function init_memory_table_size()
    /**
     * 初始化内存表行数
     *
     * @param int $num 最大行数
     *
     * @throw Exception
     *
     * @return int
     */

    protected function init_memory_table_size(int $num)
    {
        if ($num * 1.2 >= self::MEMORY_TABLE_MAX_SIZE)
        {
            throw new \Exception('分配内存太多!');
            //return false;
        }

        $size = self::MEMORY_TABLE_MIN_SIZE;

        if ($num * 2 > $size)
        {
            $size = $num * 2;
            if ($size > self::MEMORY_TABLE_MAX_SIZE)
            {
                $size = self::MEMORY_TABLE_MAX_SIZE;
            }
            else
            {
                $i   = 1;
                $tmp = self::MEMORY_TABLE_MIN_SIZE;
                while (($tmp = MEMORY_TABLE_MIN_SIZE * pow(2, $i)) < $size)
                {
                    $i ++;
                }
                $size = $tmp;
            }
        }
        return $size;
    }
    // }}}
    // {{{ protected function create_table()
    /**
     * 创建swoole_table内存表
     *
     * @return true
     */

    protected function create_table()
    {
        $this->__table = new \swoole_table($this->__size);
        foreach ($this->__field_arr as $key => $v)
        {
            $this->__table->column($key, $v['type'], $v['size']);
        }
        $this->__table->create();
        //$this->log('create swoole memory table finished. size: ' . $size, LOG_DEBUG);

        return true;
    }
    // }}}
    // {{{ public function add(string $key, array $field_arr)
    public function add(string $key, array $field_arr)
    {
        $flag = $this->check_field_data($field_arr);
        if (!$flag)
        {
            return false;
        }
        //$this->__used_lock && $this->lock();
        if ($this->is_exists($key))
        {
            $error = '数据[' . $key . ']已经存在';
            //$this->__used_lock && $this->unlock();
            return false;
        }
        $this->__table->set($key, $field_arr);
        //$this->__used_lock && $this->unlock();

        return true;
    }
    // }}}
    // {{{ public function set(string $key, array $field_arr)
    public function set(string $key, array $field_arr)
    {
        $flag = $this->check_field_data($field_arr);
        if (!$flag)
        {
            return false;
        }
        //$this->__used_lock && $this->lock();
        $this->__table->set($key, $field_arr);
        //$this->__used_lock && $this->unlock();

        return true;
    }
    // }}}
    // {{{ public function get(string $key)
    public function memory_get(string $key)
    {
        //$this->__used_lock && $this->lock();
        if (!$this->_memory_table->exist($key))
        {
            $error = '数据[' . $key . ']不存在';
            //$this->__used_lock && $this->unlock();
            return false;
        }
        $arr = $this->_memory_table->get($key);
        //$this->__used_lock && $this->unlock();

        return $arr;
    }
    // }}}
    // {{{ public function del(string $key)
    public function del(string $key)
    {
        // 基于行的原子性操作，不需要加锁
        //$this->__used_lock && $this->lock();
        if (!$this->is_exists($key))
        {
            $error = '要删除的数据[' . $key . ']不存在';
            //$this->__used_lock && $this->unlock();
            return false;
        }
        $this->_memory_table->del($key);
        //$this->__used_lock && $this->unlock();

        return true;
    }
    // }}}
    // {{{ public function is_exists(string $key)
    public function is_exists(string $key)
    {
        if (!$this->_memory_table->exist($key))
        {
            $error = '查找内存数据[' . $key . '] 不存在.';
            return false;
        }

        return true;
    }
    // }}}
    // {{{ protected function create_lock()
    protected function create_lock()
    {
        if ($this->__lock)
        {
            return $this->__lock;
        }
        $this->__lock = new \swoole_lock(SWOOLE_MUTEX);
        return $this->__lock;
    }
    // }}}
    // {{{ protected function lock()
    protected function lock()
    {
        $this->__lock->lock();

        return true;
    }
    // }}}
    // {{{ protected function unlock()
    protected function unlock()
    {
        $this->__lock->unlock();

        return true;
    }
    // }}}
    // {{{ protected function check_field_data(array $field_arr)
    protected function check_field_data(array $field_arr)
    {
        if (count($field_arr) !== $this->__field_num)
        {
            return false;
        }
        foreach ($this->__field_arr as $key => $v)
        {
            if (!isset($field_arr[$key]))
            {
                return false;
            }
            $value = $field_arr[$key];
            switch ($v['type'])
            {
                case self::MEMORY_TYPE_STRING :
                    $tmp = (string)$value;
                    if ($tmp != $value)
                    {
                        return false;
                    }
                    if (strlen($tmp) > $v['size'])
                    {
                        return false;
                    }
                    break;
                case self::MEMORY_TYPE_INT :
                    // 64位系统上PHP_INT_SIZE为8,所以不存在越界问题
                    $tmp = (int)$value;
                    if ($tmp != $value)
                    {
                        return false;
                    }
                    switch ($v['size'])
                    {
                        case self::MEMORY_LENGTH_TINYINT :
                            if ($value < -128 || $value > 127)
                            {
                                return false;
                            }
                            break;
                        case self::MEMORY_LENGTH_SMALLINT :
                            if ($value < -32768 || $value > 32767)
                            {
                                return false;
                            }
                            break;
                        case self::MEMORY_LENGTH_INT :
                            if ($value < -2147483648 || $value > 2147483647)
                            {
                                return false;
                            }
                            break;
                        case self::MEMORY_LENGTH_BIGINT :
                            if ($value < -9223372036854775808 || $value > 9223372036854775807)
                            {
                                return false;
                            }
                            break;
                        default :
                            return false;
                    }
                    break;
                case self::MEMORY_TYPE_FLOAT :
                    $tmp = (float) $value;
                    if ($tmp != $value)
                    {
                        return false;
                    }
                    break;
                default :
                    return false;
            }
        }
        return true;
    }
    // }}}
    // {{{ protected function filter_field_array(array $field_array)
    protected function filter_field_array(array $field_array)
    {
        foreach ($field_array as $key => $v)
        {
            $tmp_arr = $this->filter_var($v);
            if (!$tmp_arr)
            {
                throw \Exception('field type error.');
                return false;
            }
            $field_array[$key] = $tmp_arr;
        }
        return $field_array;
    }
    // }}}
    // {{{protected function filter_var(array $type_arr)
    protected function filter_var(array $type_arr)
    {
        if (!isset($type_arr['type']))
        {
            throw \Exception('field type is not setting.');
            //return false;
        }
        switch ($type_arr['type'])
        {
            case self::MEMORY_TYPE_STRING :
                if (!isset($type_arr['size']))
                {
                    throw \Exception('size of field type[STRING] is not setting.');
                    //return false;
                }
                $len = (int)$type_arr['size'];
                if (!$len)
                {
                    throw \Exception('size of field type[STRING] is 0');
                    //return false;
                }
                $type_arr['size'] = $len;
                break;
            case self::MEMORY_TYPE_INT :
                if (!isset($type_arr['size']))
                {
                    throw \Exception('size of field type[INT] is not setting.');
                    //return false;
                }
                $len = (int)$type_arr['size'];
                $tmp = array(
                        self::MEMORY_LENGTH_TINYINT  => true,
                        self::MEMORY_LENGTH_SMALLINT => true,
                        self::MEMORY_LENGTH_INT      => true,
                        self::MEMORY_LENGTH_BIGINT   => true,
                       );
                if (!isset($tmp[$len]))
                {
                    throw \Exception('size of field type[INT] is one of the values: ' . implode(', ', array_keys($tmp)));
                    //return false;
                }
                $type_arr['size'] = $len;
                break;
            case self::MEMORY_TYPE_FLOAT :
                $type_arr['size'] = 8;
                break;
            default :
                throw \Exception('field type[' . $type_arr['type'] . '] is not allow.');
                //return false;
        }
        return $type_arr;
    }
    // }}}

}
