module SyslogProtocol
  # These hashes stolen from Syslog.pm
  
  FACILITIES = {
    'kern'     => 0,
    'user'     => 1,
    'mail'     => 2,
    'daemon'   => 3,
    'auth'     => 4,
    'syslog'   => 5,
    'lpr'      => 6,
    'news'     => 7,
    'uucp'     => 8,
    'cron'     => 9,
    'authpriv' => 10,
    'ftp'      => 11,
    'ntp'      => 12,
    'audit'    => 13,
    'alert'    => 14,
    'at'       => 15,
    'local0'   => 16,
    'local1'   => 17,
    'local2'   => 18,
    'local3'   => 19,
    'local4'   => 20,
    'local5'   => 21,
    'local6'   => 22,
    'local7'   => 23
  }
  
  FACILITY_INDEX = {
    0   => 'kern',
    1   => 'user',
    2   => 'mail',
    3   => 'daemon',
    4   => 'auth',
    5   => 'syslog',
    6   => 'lpr',
    7   => 'news',
    8   => 'uucp',
    9   => 'cron',
    10  => 'authpriv',
    11  => 'ftp',
    12  => 'ntp',
    13  => 'audit',
    14  => 'alert',
    15  => 'at',
    16  => 'local0',
    17  => 'local1',
    18  => 'local2',
    19  => 'local3',
    20  => 'local4',
    21  => 'local5',
    22  => 'local6',
    23  => 'local7'
  }
  
  SEVERITIES = {
    'emerg'   => 0,
    'alert'   => 1,
    'crit'    => 2,
    'err'     => 3,
    'warn'    => 4,
    'notice'  => 5,
    'info'    => 6,
    'debug'   => 7 
  }
  
  SEVERITY_INDEX = {
    0  => 'emerg',
    1  => 'alert',
    2  => 'crit',
    3  => 'err',
    4  => 'warn',
    5  => 'notice',
    6  => 'info',
    7  => 'debug'
  }
end