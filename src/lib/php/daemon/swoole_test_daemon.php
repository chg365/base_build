<?php
define('PATH_ORCA_RUN', __DIR__);
require_once(__DIR__ . '/memory_table.class.php');
class swoole_test_daemon
{
    const PROCESS_NAME_MAX_LEN  = 64;
    const MEMORY_TABLE_MAX_SIZE = 4096; // 必须为2的指数
    const MEMORY_TABLE_MIN_SIZE = 128; // 必须为2的指数

    // {{{ memeber
    /**
     * 日志对象
     *
     * @var object
     */
    protected $__log = null;

    /**
     * PID 文件
     *
     * @var resource
     */
    protected $__pid_file;

    /**
     * PID 句柄
     *
     * @var resource
     */
    protected $__pid_fp;

    /**
     * 子进程最高所占内存 默认值 1G
     * 当子进程超过此值后，父进程将重启子进程
     * 各个子进程可以自己单独配置
     *
     * @var int
     */
    private $__process_max_memory = 1 * 1024 * 1024 * 1024;
    /**
     * 子进程运行的最长时间 默认值 6小时
     * 当子进程运行时间超过此值后，父进程将重启子进程
     *
     * @var int
     */
    private $__process_max_lifetime = 6 * 60 * 60;
    /**
     * 进程状态 0 正常 1 将要关闭 2重启
     *
     * @var int
     */
    private $__status = 0;

    /**
     * swoole_table对象
     *
     * @var \swoole_table
     */
    protected $__memory_table   = null;

    /**
     * 子进程配置 从配置文件解析出来的子进程名称、子进程数等配置
     *
     * @var array
     */
    private $__process_conf = array(
            'parent' => array(
                'name' => 'oc_phpd',
                ),
            'oc_process_test1' => array(
                'max_process_num'  => 5,
                'process_num'  => 3,
                'max_memory'   => 1 * 1024 * 1024 * 1024,
                'max_task_num' => 100000,
                'max_lifetime' => 1000,
                ),
            'oc_process_test2' => array(
                'max_process_num'  => 5,
                'process_num'  => 5,
                'max_memory'   => 1 * 1024 * 1024 * 1024,
                'max_task_num' => 100000,
                'max_lifetime' => 1000,
                ),
            );

    /**
     * 子进程 pid => swoole_process对象 数组
     *
     * @var array
     */
    private $__processes = array();

    /**
     * 当前存在的子进程状态
     *
     * @var array
     */
    private $__process_status  = array();

    /**
     * 统计处理业务数
     *
     * @var array
     */
    private $__statistics = array();
    // }}}

    // {{{ public function __construct()

    /**
     * 构造方法
     *
     * @return void
     */
    public function __construct()
    {
    }
    // }}}
    protected function parse_ini()
    {
        //$this->__process_conf = array();
    }
    // {{{ protected function init_daemon()

    /**
     * 初始化守护进程
     *
     * @link http://liubin.itpub.net/post/325/24427
     * @return void
     */
    protected function init_daemon()
    {
        // 解析、读取配置文件
        $this->parse_ini();
        // daemon 模式 这行代码会导致pid改变
        swoole_process::daemon();
        $parent_name = $this->__process_conf['parent']['name'];
        //$this->__pid_file = PATH_ORCA_RUN . $parent_name . '.pid';

        if (!$this->__pid_file)
        {
            $this->log('daemon[' . $parent_name . '] pid file is not setting!', LOG_INFO);
            exit(1);
        }

        if (is_file($this->__pid_file))
        {
            //$this->log('daemon[' . $parent_name . '] is aready exists!', LOG_INFO);
            $this->log('pid file[' . $this->__pid_file . '] is already exist.', LOG_INFO);
            exit(1);
        }

        $pid_dir = dirname($this->__pid_file);
        if (!is_dir($pid_dir) || !is_writable($pid_dir))
        {
            $this->log('pid dir[' . $pid_dir . '] is not exists or is not writable!', LOG_INFO);
            exit(1);
        }

        // 锁定pid文件,并写入进程号
        if (!$this->lock_pid())
        {
            $this->log('lock pid failed.', LOG_INFO);
            exit(1);
        }
        // 忽略终端 I/O信号,STOP信号
        pcntl_signal(SIGTTOU, SIG_IGN);
        pcntl_signal(SIGTTIN, SIG_IGN);
        pcntl_signal(SIGTSTP, SIG_IGN);
        pcntl_signal(SIGHUP, SIG_IGN);

        // 设置父进程名
        $parent_name = $this->__process_conf['parent']['name'];
        unset($this->__process_conf['parent']);
        swoole_set_process_name($parent_name);


        // 创建内存表
        $this->create_memory_table();

        // 关闭所有打开的资源
        // 当关闭后，再输出，PHP会直接退出
        /*
        fclose(STDIN);
        fclose(STDOUT);
        fclose(STDERR);
        */

        $this->log('init_daemon success.', LOG_DEBUG);
    }

    // }}}
    // {{{ public function set_pid_file()

    /**
     * 设置PID文件
     *
     * @param string $file
     * @return boolean
     */
    public function set_pid_file($file)
    {
        $this->__pid_file = $file;
    }

    // }}}
    // {{{ public function set_log()

    /**
     * 设置日志对象
     *
     * @param object $log
     * @return void
     */
    public function set_log($log)
    {
        $this->__log = $log;
    }

    // }}}
    // {{{ public function stop()

    /**
     * 停止服务
     *
     * @return void
     */
    public function stop()
    {
        if (!$this->__pid_file || !is_file($this->__pid_file) || !is_readable($this->__pid_file))
        {
            $this->log('pid file is not exsits.', LOG_INFO);
            exit(1);
        }
        $pid = file_get_contents($this->__pid_file);
        if (!$pid) {
            $this->log('get the pid failed.', LOG_INFO);
            exit(1);
        }
        if (!$this->kill($pid, 0)) {
            $this->log("process [$pid] is not running.", LOG_INFO);
            exit(1);
        }
        /*
        if ($this->lock_pid(null, false)) {
            $this->log("process [$pid] is not running.", LOG_INFO);
            exit(1);
        }
        */
        if (!$this->kill($pid, SIGTERM)) {
            //$this->log(posix_strerror(posix_get_last_error()), LOG_INFO);
            $this->log('swoole_process::kill pid[' . $pid . '] SIGTERM failed.', LOG_INFO);
            exit(1);
        }
        return ;
    }
    // }}}
    // {{{ public function start()

    /**
     * 启动服务
     *
     * @return void
     */
    public function start()
    {
        return $this->run();
    }
    // }}}
    // {{{ public function stat()

    /**
     * 查看服务状态
     *
     * @return void
     */
    public function stat()
    {
        if (!$this->__pid_file || !is_file($this->__pid_file) || !is_readable($this->__pid_file))
        {
            $this->log('pid file is not exsits.', LOG_INFO);
            exit(1);
        }
        $pid = file_get_contents($this->__pid_file);
        if (!$pid) {
            $this->log('get the pid failed.', LOG_INFO);
            exit(1);
        }
        if (!swoole_process::kill($pid, 0)) {
            $this->log("process [$pid] is not running.", LOG_INFO);
            exit(1);
        }
        /*
        if ($this->lock_pid(null, false)) {
            $this->log("process [$pid] is not running.", LOG_INFO);
            exit(1);
        }
        */
        if (!swoole_process::kill($pid, SIGTERM)) {
            //$this->log(posix_strerror(posix_get_last_error()), LOG_INFO);
            $this->log('swoole_process::kill pid[' . $pid . '] SIGTERM failed.', LOG_INFO);
            exit(1);
        }
        return ;
    }
    // }}}
    // {{{ protected function create_memory_table()

    /**
     * 创建内存表
     *
     * @return void
     */
    protected function create_memory_table()
    {
        $field_arr = array(
                'pid'       => array(
                    'type' => memory_table::MEMORY_TYPE_INT,
                    'size' => memory_table::MEMORY_LENGTH_INT,
                    ), // pid
                'name'      => array(
                    'type' => memory_table::MEMORY_TYPE_STRING,
                    'size' => self::PROCESS_NAME_MAX_LEN,
                    ), // 进程名
                'init_time' => array(
                    'type' => memory_table::MEMORY_TYPE_INT,
                    'size' => memory_table::MEMORY_LENGTH_BIGINT,
                    ), // 进程启动时间
                'memory'    => array(
                    'type' => memory_table::MEMORY_TYPE_INT,
                    'size' => memory_table::MEMORY_LENGTH_BIGINT,
                    ), // 当前使用内存
                'total'     => array(
                    'type' => memory_table::MEMORY_TYPE_INT,
                    'size' => memory_table::MEMORY_LENGTH_INT,
                    ),  // 当前处理业务总数
                'fail'      => array(
                    'type' => memory_table::MEMORY_TYPE_INT,
                    'size' => memory_table::MEMORY_LENGTH_INT,
                    ),  // 处理业务失败数
                );
        $process_num = 1;
        foreach ($this->__process_conf as $name => $v)
        {
            $process_num += isset($v['max_process_num']) ? $v['max_process_num'] : $v['process_num'];
        }
        $this->__memory_table = new memory_table($field_arr, $process_num);
        return true;
    }

    // }}}
    // {{{ protected function log()

    /**
     * 记录日志
     *
     * @param string $message
     * @param integer $priority
     * @return void
     */
    protected function log($message, $priority)
    {
        if (!$this->__log) {
            error_log($message . PHP_EOL, 3, '/tmp/2.log');
            return ;
        }

        try {
            $this->__log->log($message, $priority);
        } catch (exception $e) {
            echo $e; // 记录日志失败
        }
    }

    // }}}
    // {{{ protected function _stop()

    /**
     * 停止服务
     *
     * @return void
     */
    protected function _stop()
    {
        $this->__status = 1;
        //停止子进程


    }
    // }}}
    // {{{ protected function _reload()

    /**
     * 重载配置文件
     *
     * @return void
     */
    protected function _reload()
    {
        $this->__status = 2;
        // 读取配置

        //停止子进程


    }
    // }}}
    // {{{ protected function _restart()

    /**
     * 重启服务
     *
     * @return void
     */
    protected function _restart()
    {
        $this->__status = 2;

        $arr = $argv;
        //停止子进程


        // 重启当前父进程
        $process = new swoole_process(function (swoole_process $process) use ($arr)
        {
            swoole_process::daemon();
            $execfile = $argv[0];
            if (!$execfile)
            {
                return false;
            }
            unset($arr[0]);
            $process->exec($execfile, $arr);
        });
        $process->start();

        // 当前进程退出
        exit;
    }
    // }}}
    // {{{ public function run()

    /**
     * 运行服务
     *
     * @return void
     */
    public function run()
    {
        $this->init_daemon();

        $_this = $this;
        foreach ($this->__process_conf as $name => $v)
        {
            $this->__statistics[$name] = array('total' => 0, 'fail' => 0);
            for ($i = 0; $i < $v['process_num']; $i++)
            {
                $process = new swoole_process(function(swoole_process $process) use ($_this, $name)
                {
                    $_this->subprocess($process, $_this->__memory_table, $name);
                }, false, 2);
                $pid = $process->start();
                $this->__processes[$pid] = $process;
                $status = array('init_time' => time(),
                        'name' => $name,
                        'total' => 0, // 处理业务总数
                        'fail' => 0, //  处理业务失败数
                        'memory' => 0, // 占用内存
                        );
                $this->__process_status[$pid] = $status;
            }
        }

        // 父进程信号

        if (!$this->signal(SIGTERM, [$this, 'handler_sigterm'])) {
            exit(1);
        }

        // 回收结束运行的子进程
        if (!$this->signal(SIGCHLD, [$this, 'handler_sigchld'])) {
            exit(1);
        }

        /*
        // 添加事件，进程间通信
        foreach ($this->__processes as $pid => $process)
        {
            swoole_event_add($process->pipe, function($pipe) use ($_this, $pid, $process) {
                $_this->pipe_read_event($process, $pid);
            });
        }
        */
        while (true)
        {
            // 监控子进程变化
            pcntl_signal_dispatch();
            echo "11111111111" . PHP_EOL;
            if ($this->__status == 1 && !$this->__processes)
            {
                echo "2222222222" . PHP_EOL;
                exit(0);
            }
            sleep(1);
        }
    }

    // }}}
    // {{{ public function pipe_read_event()

    /**
     * 父进程读取子进程管道数据
     *
     * @return boolean
     */
    public function pipe_read_event(swoole_process $process, int $pid)
    {
        $data = $process->read();
        $data = trim($data);
        if (strpos($data, 'a:') === 0 && substr($data, -1, 1) === '}') {
            $data1 = unserialize($data);
            if ($data1 === false) {
                $this->log('Warning: pipe data type error. data: ' . $data, LOG_INFO);
                return false;
            }
        } else {
            $arr   = explode($data, ':', 2) + array('', '');
            $type  = trim($arr[0]);
            $data  = trim($arr[1]);
            $data1 = array($type => $data);
        }

        $is_kill = true;
        foreach ($data1 as $type => $data) {
            unset($data1[$type]);
            $flag = $this->_deal_subprocess_data($pid, $type, $data, $is_kill);
            if ($flag == 4) {
                $is_kill = false;
            }
        }
    }

    // }}}
    // {{{ protected function _deal_subprocess_data()
    /**
     * 处理子进程回写的数据
     *
     * @param int $pid
     * @param string $type
     * @param string $data
     * @param boolean $is_kill 是否结束子进程
     * @return mixed  boolean true 成功, false 失败, 4 杀掉进程 
     *
     */
    protected function _deal_subprocess_data(int $pid, string $type, string $data, $is_kill = true)
    {
        $is_killed = false;// 是否杀掉子进程
        $name      = $this->__process_status[$pid]['name'];
        switch ($type) {
            case 'memory' : // 子进程报告内存使用量
                $data1 = (int)$data;
                if (!$data1) {
                    $error = 'Warning: pipe data[memory type] error. data: ' . $data;
                    $this->log($error, LOG_INFO);
                    return false;
                }
                $this->__process_status[$pid]['memory'] = $data1;

                // 子进程内存使用高于配置的最大值后，重启子进程
                if ($is_kill && $data1 >= $this->__process_conf[$name]['max_memory']) {
                    $is_killed = true;
                    $flag = $this->kill($pid, SIGHUP);
                    if (!$flag) {
                        return false;
                    }
                }
                break;
            case 'atomic' :  // 子进程报告新增处理业务数量
                $len     = strlen($data);
                $is_fail = false;
                if ($len > 0 && substr($data, -1, 1) == '-') {
                    $data    = substr($data, 0, $len - 1);
                    $is_fail = true;
                }
                $data1 = (int)$data;
                if (!$data1) {
                    $error = 'Warning: pipe data[atomic type] error. data: '  . $data;
                    $this->log($error, LOG_INFO);
                    break;
                }

                $this->__process_status[$pid]['total'] += $data1;
                if ($is_fail) {
                    $this->__process_status[$pid]['fail'] += $data1;
                }

                $total = $this->__process_status[$pid]['total'];
                $max   = $this->__process_conf[$name]['max_task_num'];
                $fail  = $this->__process_status[$pid]['fail'];

                // 子进程处理的业务数高于配置的最大值后，重启子进程
                // 或者失败数太高，也重启子进程
                if ($is_kill && ( $total >= $max || $total > 100 && ($fail / $total) > 0.5)) {
                    $is_killed = true;
                    $flag = $this->kill($pid, SIGHUP);
                    if (!$flag) {
                        return false;
                    }
                }
                break;
            case 'lifetime' :
                $init_time = $this->__process_status[$pid]['init_time'];
                $max_lifetime = $this->__process_conf[$name]['max_lifetime'];
                if ($is_kill && (time() - $init_time) >= $max_lifetime) {
                    $is_killed = true;
                    $flag = $this->kill($pid, SIGHUP);
                    if (!$flag) {
                        return false;
                    }
                }
                break;
            case 'busy' :
                $this->__process_status[$pid]['busy'] = (boolean)$data;
                break;
            default :
                $error = 'method[' . __METHOD__ . '] read unkown data type. data: [' . $type . ':' . $data . ']';
                $this->log($error, LOG_INFO);
                return false;
                break;
        }
        if ($is_killed) {
            return 4;
        }
        return true;
    }
    // }}}
    // {{{ protected function kill()

    /**
     * 杀掉进程
     *
     * @param int $pid 进程号
     * @param int $signo 信号
     * @return boolean
     */
    protected function kill($pid, $signo = SIGTERM)
    {
        $this->log('kill pid[' . $pid . '] signo[' . $signo . '] start ...', LOG_DEBUG);
        if (!swoole_process::kill($pid, $signo)) {
            $this->log('swoole_process::kill pid[' . $pid . '] signo[' . $signo . '] failed.', LOG_INFO);
            return false;
        }
        $this->log('kill pid[' . $pid . '] signo[' . $signo . '] finished ...', LOG_DEBUG);
        return true;
    }

    // }}}
    // {{{ public function subprocess(swoole_process $process, $memory_table, string $name)
    /**
     * 子进程执行
     *
     * @param \swoole_process $process 子进程swoole_process对象
     * @param \memory_table 内存表对象
     * @param string $name 进程显示名 ps -ef显示的名字
     */
    public function subprocess(swoole_process $process, $memory_table, string $name)
    {
        $process->name($name);

        $config = $this->__process_conf[$name];

        $class_name = $name;
        $function   = 'run';

        if (!class_exists($class_name))
        {
            $error = 'class['  .$class_name . ']is not exists.' . PHP_EOL;
            //$this->log($error, LOG_INFO);
            exit(1);
        }
        if (isset($config['function']))
        {
            if (method_exists($class_name, $config['function']))
            {
                $function = $config['function'];
            }
            else
            {
                $error = 'Notice: Method[' . $config['function'] . '] in class[' . $class_name . '] does  not exist.';
                $this->log($error, LOG_INFO);
            }
        }
        //$function   = isset($config['function']) && method_exists($config['function']) ? $config['function'] : 'run';

        unset($config['name'], $config['max_process_num'], $config['process_num']);

        //pcntl_signal_dispatch();

        $obj = new $class_name($process, $memory_table, $config);
        //$obj->$function();
        $obj->run();
        //$process->write($process->pid);
    }
    // }}}
    // {{{ public function handler_sigterm()

    /**
     * SIGTERM 信号处理函数
     *
     * @return void
     */
    public function handler_sigterm($signo)
    {
        $this->__status = 1;
        $ppid     = posix_getpid();
        $pname    = cli_get_process_title();
        $message = 'parent process [pid: ' . $ppid . '] [name: ' . $pname . '] catch signal SIGTERM, exiting...';
        $this->log($message, LOG_DEBUG);
        echo "aaaaaaaaaaaaa" . PHP_EOL;
        // 重置SIGTERM信号处理器, 用空函数替换，不然kill(0, SIGTERM)还会执行一次
        $this->signal(SIGTERM, function($signo) {});
        // 重置SIGCHLD信号处理器, 用空函数替换
        $this->signal(SIGCHLD, function($signo) {});

        if (!$this->kill(0, SIGTERM)) {
            return;
        }

        /*
        // 杀掉子进程
        foreach ($this->__processes as $pid => $process)
        {
            // 先删除绑定的事件
            if (!swoole_event_del($process->pipe)) {
                $this->log("free child {$name}[{$pid}], delete event faild.", LOG_DEBUG);
            }
            // 再关闭管道
            $process->close();
            if (!$this->kill($pid, SIGTERM)) {
                //return;
                continue;
            }
        }
        */

        $this->log('wait all subprocess exit ....', LOG_DEBUG);
        // 等待子进程全部退出
        while (($pid = pcntl_wait($status/*, WNOHANG | WUNTRACED*/)) != -1)
        {
            $name = $this->__process_status[$pid]['name'];
            $this->log("child name[$name] pid[$pid] exit, status: $status", LOG_DEBUG);
            $this->_free_child($pid, $status);
        }
        $this->log('all subprocesses are exit.', LOG_DEBUG);
        $this->_free_parent($pid);
        $message = 'parent process [pid: ' . $ppid . '] [name: ' . $pname . '] exit by signal SIGTERM';
        $this->log($message, LOG_DEBUG);
        echo "bbbbbbbbbbbb" . PHP_EOL;
        exit(0);
    }

    // }}}
    // {{{ public function handler_sigchld()

    /**
     * SIGCHLD信号处理函数，子进程退出，回收资源等
     *
     * @return void
     */
    public function handler_sigchld()
    {
        $ppid     = posix_getpid();
        $pname   = cli_get_process_title();
        $message = 'parent process [pid: ' . $ppid . '] [name: ' . $pname . '] catch signal SIGCHLD ...';

        $this->log($message, LOG_DEBUG);

        while (($pid = pcntl_wait($status, WNOHANG/* | WUNTRACED*/)) > 0)
        {
            /*
            if ($pid == 0)
            {
                break;
            }
            */
            $name = $this->__process_status[$pid]['name'];
            $this->log("child name[$name] pid[$pid] exit status: $status", LOG_DEBUG);
            $this->_free_child($pid, $status);
            /*
            // 退出状态码 正常退出
            if ($code == 0) {
                ;
            } else {
                $this->log('child name[' . $name . '] pid[' . $pid . '] 子进程未知退出状态码 code: ' . $code . PHP_EOL, LOG_INFO);
            }
            */
        }
        // 没有子进程时，父进程是否也要退出运行呢？
        if ($pid == -1)
        {
            //exit(0);
            ;
        }
    }

    // }}}
    // {{{ protected function signal()

    /**
     * 安装一个信号处理器
     *
     * @param int $signo 信号编号
     * @param callback $callback 回调函数
     * @return boolean
     */
    protected function signal(int $signo, $callback)
    {
        //if (!swoole_process::signal($signo, $callback))
        if (!pcntl_signal($signo, $callback))
        {
            $this->log('class[' . __CLASS__ . '] set signal handler failed.', LOG_INFO);
            return false;
        }
        return true;
    }
    // }}}
    // {{{ protected function _free_child()

    /**
     * 回收资源
     *
     * @param integer $pid
     * @param integer $status
     * @return void
     */
    protected function _free_child($pid, $status)
    {
        $name = $this->__process_status[$pid]['name'];
        $this->log("free child {$name}[{$pid}], child status: $status", LOG_DEBUG);

        // 在进程结束时，更新统计
        $this->__statistics[$name]['total'] += $this->__process_status[$pid]['total'];
        $this->__statistics[$name]['fail']  += $this->__process_status[$pid]['fail'];

        // 删除绑定的事件
        /*
        if (!swoole_event_del($this->__processes[$pid]->pipe)) {
            $this->log("free child {$name}[{$pid}], delete event faild.", LOG_DEBUG);
        }
        */
        // 删除
        unset($this->__processes[$pid], $this->__process_status[$pid]);
        /**

        if (!$this->__has_init) { // 初始化阶段
            if (pcntl_wifexited($status) && !pcntl_wexitstatus($status)) { // 正常退出
                return ;
            }
            $this->__pids = array();
            posix_kill(0, SIGTERM);
            $this->log("fork process `$name` failed, exit.", LOG_INFO);
            $this->_del_counter($pid, true);
            exit(1);
        }

        if (!isset($this->__process_cfg[$name]['type'])
                || self::P_TYPE_DAEMON <> $this->__process_cfg[$name]['type']) {
            return ;
        }

        if (isset($this->__retry_info[$name])) {
            $this->__retry_info[$name]['proc_num']++;
        } else {
            $this->__retry_info[$name] = array('proc_num' => 1, 'retry_times' => 0, 'last_retry' => 0);
        }

        $this->__retry_info[$name]['old_pid'][$pid] = $pid;
        **/
    }

    // }}}
    // {{{ protected function _free_parent()

    /**
     * 父进程退出
     *
     * @param int $pid
     * @return boolean
     */
    protected function _free_parent($pid)
    {
        $this->log('parent exit ..., unlink pid file[' .$this->__pid_file . '] start...', LOG_DEBUG);
        if (!unlink($this->__pid_file))
        {
            $this->log('unlink pid file[' .$this->__pid_file . '] failed', LOG_INFO);
            return false;
        }
        $this->log('parent exit ..., unlink pid file[' .$this->__pid_file . '] finishid', LOG_DEBUG);
        //$this->_del_counter($pid, true);
        return true;
    }

    // }}}

    // {{{ protected function lock_pid()

    /**
     * 锁定PID文件
     *
     * @param string $file
     * @param boolean $write_pid
     * @return boolean
     */
    protected function lock_pid($file = null, $write_pid = true)
    {
        if (!isset($file)) {
            $file = $this->__pid_file;
        }
        $fp = dio_open($file, O_WRONLY|O_CREAT, 0644);
        if (!$fp || dio_fcntl($fp, F_SETLK, array('type' => F_WRLCK))) {
            return false;
        }

        if (!$write_pid) {
            return true;
        }

        if (!dio_truncate($fp, 0)) {
            return false;
        }
        dio_write($fp, posix_getpid());
        $this->__pid_fp = $fp;
        return true;
    }

    // }}}
    // {{{ public function handler_sighup()

    /**
     * 处理重载配置信号
     *
     * @return void
     */
    public function handler_sighup()
    {
        $this->log('catch signal SIGHUP, reconfig...', LOG_DEBUG);
        $new_cfg = $this->process_cfg();
        if (false === $new_cfg) {
            $this->log('process config failed.', LOG_INFO);
            return ;
        }
        $old_cfg = $this->__process_cfg;

        // 处理减少的进程
        $process_info = array();
        foreach ($this->__pids as $pid => $process_name) {
            $process_info[$process_name][] = $pid;
        }

        foreach ($process_info as $proc_name => $pids) {
            $count = count($pids);
            if (!isset($new_cfg[$proc_name])) {
                // 删除全部
            } elseif ($new_cfg[$proc_name]['max_process'] < $count) {
                $count = $new_cfg[$proc_name]['max_process'];
                while ($count > 0) {
                    array_pop($pids);
                    $count--;
                }
            } else {
                continue ;
            }

            foreach ($pids as $pid) {
                $this->log("reconfig, stop child {$this->__pids[$pid]}[$pid]", LOG_DEBUG);
                unset($this->__pids[$pid]);
                if (!posix_kill($pid, SIGTERM)) {
                    $this->log(posix_strerror(posix_get_last_error()), LOG_DEBUG);
                }
            }
        }

        $this->set_process_cfg($new_cfg);
        $new_cfg = $this->__process_cfg;

        // 处理新增的进程
        foreach ($new_cfg as $proc_name => $cfg) {
            if (!isset($old_cfg[$proc_name])) {
                $max_process = $cfg['max_process'];
            } else {
                $max_process = $cfg['max_process'] - $old_cfg[$proc_name]['max_process'];
            }

            if (0 >= $max_process) { // 不变或减少
                continue ;
            }

            if (!isset($this->__retry_info[$proc_name])) {
                $this->__retry_info[$proc_name] = array('proc_num' => 0, 'retry_times' => 0, 'last_retry' => 0);
            }

            while ($max_process--) {
                $this->__retry_info[$proc_name]['proc_num']++;
            }
        }
    }

    // }}}
    // {{{ public function handler_sigusr1()

    /**
     * 获取进程统计
     *
     * @return void
     */
    public function handler_sigusr1()
    {
        $this->log('catch signal SIGUSR1, stat process...', LOG_DEBUG);
        $dio = @dio_open($this->__fifo_file, O_RDWR|O_NONBLOCK);
        if (!$dio) {
            $this->log("open fifo `{$this->__fifo_file}` failed.", LOG_DEBUG);
            return ;
        }

        try {
            $stat = $this->__counter->stat();
            $this->_write_fifo($dio, json_encode($stat), true); // 成功
            dio_close($dio);
        } catch (exception $e) {
            $this->log($e->getMessage(), LOG_DEBUG);
            $this->_write_fifo($dio, $e->getMessage(), false); // 失败
            dio_close($dio);
        }
    }

    // }}}
    // {{{ public function handler_sigusr2()

    /**
     * 查看进程状态
     *
     * @return void
     */
    public function handler_sigusr2()
    {
        $this->log('catch signal SIGUSR2, watching process...', LOG_DEBUG);
        $dio = @dio_open($this->__fifo_file, O_RDWR|O_NONBLOCK);
        if (!$dio) {
            $this->log("open fifo `{$this->__fifo_file}` failed.", LOG_DEBUG);
            return ;
        }

        $message = "PID: " . posix_getpid()."\n"
                 . "Process info:\n"
                 . var_export($this->__pids, true);

        $this->_write_fifo($dio, $message, true); // 成功
        dio_close($dio);
    }

    // }}}
    // {{{ protected function init_memory_table_size()
    protected function init_memory_table_size(int $process_num)
    {
        $size = self::MEMORY_TABLE_MIN_SIZE;

        if ($process_num * 2 > $size)
        {
            $size = $process_num * 2;
            if ($size > self::MEMORY_TABLE_MAX_SIZE)
            {
                if ($process_num * 1.2 < self::MEMORY_TABLE_MAX_SIZE)
                {
                    $size = self::MEMORY_TABLE_MAX_SIZE;
                }
                else
                {
                    //throw new \Exception('Too much worker num!');
                    return false;
                }
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
    // {{{ protected function create_memory_table()
    /*
    protected function create_memory_table()
    {
        $size = $this->init_memory_table_size();
        $this->_memory_table = new \swoole_table($size);
        //$this->_memory_table->column('id', \swoole_table::TYPE_INT, 4);       //1,2,4,8
        $this->_memory_table->column('node', \swoole_table::TYPE_INT, 1);       //1,2,4,8
        $this->_memory_table->column('md5', \swoole_table::TYPE_STRING, 32);
        $this->_memory_table->column('size', \swoole_table::TYPE_INT, 4);
        $this->_memory_table->column('time', \swoole_table::TYPE_INT, 4);
        $this->_memory_table->create();
        $this->log('create swoole memory table finished. size: ' . $size, LOG_DEBUG);

        return true;
    }
    */
    // }}}

}
// {{{ abstract class oc_process
abstract class oc_process
{
    // {{{ members
    /**
     * 当前进程的进程号
     *
     * @var int
     */
    protected $__pid;

    /**
     * 当前进程的进程名称
     *
     *
     * @var string
     */
    protected $__pname = '';

    /**
     * 日志对象
     *
     * @var object
     */
    protected $__log = null;

    /**
     * swoole_process 对象
     *
     * @var swoole_process
     */
    protected $__process = null;

    /**
     * 配置信息数组
     *
     * @var array
     */
    protected $__config = array();

    /**
     * 内存表对象
     *
     * @var \swoole_table
     */
    protected $__memory_table = null;

    // }}} end members
    // {{{ functions
    // {{{ public function __construct()

    /**
     * 构造方法
     *
     * @param swoole_process $process
     * @param array $config
     * @return void
     */
    public function __construct(swoole_process $process, $memory_table, array $config)
    {
        $this->__pid   = posix_getpid();
        $this->__pname = cli_get_process_title();
        $this->log('name[' . $this->__pname . '] pid[' . $this->__pid . '] __construct start.', LOG_DEBUG);

        $this->__process = $process;
        $this->__config = $config;
        $this->__memory_table = $memory_table;

        if (!$this->signal(SIGHUP, [$this, 'handler_sighup']))
        {
            $this->__process->exit(1);
        }
        if (!$this->signal(SIGTERM, [$this, 'handler_sigterm']))
        {
            $this->__process->exit(1);
        }
    }

    // }}}
    abstract public function run();
    // {{{ public function set_log()

    /**
     * 设置日志对象
     *
     * @param object $log
     * @return void
     */
    public function set_log($log)
    {
        $this->__log = $log;
    }

    // }}}
    // {{{ public function log()

    /**
     * 记录日志
     *
     * @param string $message
     * @param integer $priority
     * @throw exception
     * @return void
     */
    public function log($message, $priority)
    {
        if (!$this->__log) {
            error_log($message . PHP_EOL, 3, '/tmp/2.log');
            return ;
        }

        try {
            $this->__log->log($message, $priority);
        } catch (exception $e) {
            echo $e; // 记录日志失败
        }
    }

    // }}}
    // {{{ public function handler_sighup()

    /**
     * 处理重载配置信号
     *
     * @return void
     */
    public function handler_sighup()
    {
        $message = 'subprocess name[' . cli_get_process_title()
                 . '] pid[' . $this->__pid . '] catch signal SIGHUP, exiting...';
        $this->log($message, LOG_DEBUG);
        $this->__process->exit(0);
    }
    // }}}
    // {{{ public function handler_sigterm()

    /**
     * SIGTERM 信号处理函数
     *
     * @return void
     */
    public function handler_sigterm()
    {
        $message = 'subprocess name[' . cli_get_process_title()
                 . '] pid[' . $this->__pid . '] catch signal SIGTERM, exiting...';
        $this->log($message, LOG_DEBUG);
        $this->__process->exit(0);
    }
    // }}}
    // {{{ public function report_status()
    /**
     * 报告子进程状态
     *
     * @param int $count 完成的任务数
     * @param boolean 完成的任务是否成功 true 成功, false 失败
     * @param boolean $is_busy 是否忙碌
     * @return void
     */
    public function report_status($count = 1, $flag = true, $is_busy = false)
    {
        $array = array(
                'atomic'   => $count . ($flag ? '' : '-'),
                'memory'   => memory_get_usage(true),
                'lifetime' => time(),
                'busy'     => (int)$flag,
                );
        $this->__process->write(serialize($array));
    }
    // }}}
    // {{{ public function report_finished_task_num()
    /**
     * 报告完成任务数, 父进程做统计和汇总，这里子进程只要通知父进程，在上次报千后又完成的数量
     *
     * @param int $count 完成的任务数
     * @param boolean $flag 完成的任务是否成功 true 成功, false 失败
     * @return void
     */
    public function report_finished_task_num($count = 1, $flag = true)
    {
        $this->__process->write('atomic:' . $count . ($flag ? '' : '-'));
    }
    // }}}
    // {{{ public function report_current_memory()
    /**
     * 报告当前进程内存占用
     *
     * @return void
     */
    public function report_current_memory()
    {
        //$memory = memory_get_peak_usage(true);
        $memory = memory_get_usage(true);
        $this->__process->write('memory:' . $memory);
    }
    // }}}
    // {{{ public function report_current_lifetime()
    /**
     * 报告子进程执行的时间
     *
     * @return void
     */
    public function report_current_lifetime()
    {
        // 这个数据没意思，在父进程中记时，这里只是通知父进程处理
        $this->__process->write('lifetime:' . time()); 
    }
    // }}}
    // {{{ public function report_current_busy()
    /**
     * 报告当前进程是否忙碌，比如待处理任务队列,积压太多需要处理的业务
     *
     * @param boolean $is_busy true 忙碌, false 空闲
     * @return void
     */
    public function report_current_busy($is_busy = true)
    {
        $this->__process->write('busy:' . ((int)(boolean)$is_busy));
    }
    // }}}
    // {{{ protected function signal_dispatch()
    /**
     * 调用等待信号的处理器
     *
     * @return boolean
     */
    protected function signal_dispatch()
    {
        return pcntl_signal_dispatch();
    }
    // }}}
    // {{{ protected function signal()

    /**
     * 安装一个信号处理器
     *
     * @param int $signo 信号编号
     * @param callback $callback 回调函数
     * @return boolean
     */
    protected function signal(int $signo, $callback)
    {
        //if (!swoole_process::signal($signo, $callback))
        if (!pcntl_signal($signo, $callback))
        {
            $this->log('class[' . __CLASS__ . '] set signal handler failed.', LOG_INFO);
            return false;
        }
        return true;
    }
    // }}}

    // }}} end functions
}
// }}}
// {{{ class oc_process_test1 extends oc_process
class oc_process_test1 extends oc_process
{
    public function run()
    {
        $this->signal_dispatch();
        while (true)
        {
            $count      = 1;
            $is_busy    = false;
            $is_success = true;
            if (rand(1, 10) === 1) {
                $is_busy = true;
            }
            if (rand(1, 100000) === 1) {
                $is_success = false;
            }
            $this->report_status($count, $is_success, $is_busy);
            error_log(date('Y-m-d H:i:s') . "\t" . 'test1' . PHP_EOL, 3, '/tmp/1.log');
            $this->signal_dispatch();
            sleep(rand(1, 10));
        }
    }
}
// }}}
// {{{ class oc_process_test2 extends oc_process
class oc_process_test2 extends oc_process
{
    public function run()
    {
        $init_time = time();
        error_log($this->__pid . "\tinit_time: " . $init_time . PHP_EOL, 3, '/tmp/1.log');
        while (true) {
            $count      = 1;
            $is_busy    = false;
            $is_success = true;
            if (rand(1, 10) === 1) {
                $is_busy = true;
            }
            if (rand(1, 100000) === 1) {
                $is_success = false;
            }
            $this->report_status($count, $is_success, $is_busy);
            error_log(date('Y-m-d H:i:s') . "\t" . 'test2' . PHP_EOL, 3, '/tmp/1.log');
            $this->signal_dispatch();
            sleep(rand(1, 10));
            error_log($this->__pid . "\ttime: " . time() . PHP_EOL, 3, '/tmp/1.log');
            error_log($this->__pid . "\tdiff time: " . (time() - $init_time) . PHP_EOL, 3, '/tmp/1.log');
            if (time() - $init_time > 10) {
                error_log($this->__pid . "\t正常结束" . PHP_EOL, 3, '/tmp/1.log');
                $this->__process->exit(0);
            }
            $this->signal_dispatch();
        }
    }
}
// }}}

$daemon = new swoole_test_daemon();
$daemon->set_pid_file(__DIR__ . '/em_test.pid');
$daemon->run();
//$daemon->stat();
