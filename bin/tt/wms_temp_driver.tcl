# команды без параметров
set command(stop) {1}
set command(run) {2}
set command(ask) {3}
set command(getpar) {14 0}
set command(restart) {16}
# команды с параметрами
set command(ozuwrbeg) {17}
set command(ozuwrnxt) {18}
set command(ozuwrend) {19}

# Запрос команды без параметров
proc azapros { name len } {
global config command inbuf

#puts "azapros"
#update

# 27=1BH -> ESC
  set fcmd(0) 27
  set ncmd 2
  foreach {b} $command($name) {
  	set fcmd($ncmd) $b
  	incr ncmd
  }
#NB Количество байт сообщения не включая ESC,NB,KS
  set fcmd(1) [expr {($ncmd-2)&255}]
#KS контрольная сумма
  set ksinp 0
  for {set i 0} {$i<$ncmd} {incr i} {
   set ksinp [expr {$ksinp+$fcmd($i)}]
  }
  set ksinp [expr {13 - ($ksinp&255)}]
  set fcmd($ncmd) $ksinp
  incr ncmd
# convert to binary
  for {set i 0} {$i<$ncmd} {incr i} {
  	set cmd($i) [binary format c $fcmd($i)]
  }
# Open port
#puts "Ready to send"
#update
  set fh $config(port)
  set ninp 0
  set ks 27
# Send request
  for {set i 0} {$i<$ncmd} {incr i} {
    puts -nonewline $fh $cmd($i)
  }
  flush $fh
# Get respond
  while {1} {
   set ddd [read $fh 1]
#puts "dddA $ddd"
update
   if {$ddd==""} {
     tk_messageBox -message "Нет связи" -title "Error" -type ok -icon error
     break
   }
   binary scan $ddd c bt
#puts "btA $bt"
update
   if {$bt==27} break
  }
  set ddd [read $fh 1]
  binary scan $ddd c ninp
  set ks [expr {$ks+$ninp}]
  set inbuf(0) $ninp

  set ninpd [expr {$ninp+2}]
  for {set i 1} {$i<$ninpd} {incr i} {
    set ddd [read $fh 1]
#    binary scan $ddd c inbuf($i)
    binary scan $ddd c num
    set inbuf($i) [expr {( $num + 0x100 ) % 0x100}]
    set ks [expr {$ks+$inbuf($i)}]
  }
  set ks [expr {$ks&255}]
  return $ks
}

# Запрос команды  с бинарными данными (для загрузки задания)
proc bzapros { name len blen offset} {
global command task inbuf
global config

#puts "bzapros"
update
  set fcmd(0) 27
  set ncmd 2

  foreach {b} $command($name) {
  	set fcmd($ncmd) $b
  	incr ncmd
  }

# add binary data
  set lbt [expr {$len - 1}]
  if {$blen < $lbt} { set lbt $blen }
  for {set i 0} {$i<$lbt} {incr i} {
  	set j [expr {$offset + $i}]
  	set x 0
  	scan $task($j) %c x
  	set fcmd($ncmd) $x
puts -nonewline "$fcmd($ncmd):"
  	incr ncmd
  }
#puts ""
#update

# Записали длину команды
  set fcmd(1) [expr {($ncmd-2)&255}]

# контрольная сумма
  set ksinp 0
  for {set i 0} {$i<$ncmd} {incr i} {
   set ksinp [expr {$ksinp+$fcmd($i)}]
  }
  set ksinp [expr {13 - ($ksinp&255)}]
  set fcmd($ncmd) $ksinp
  incr ncmd
# convert to binary
  for {set i 0} {$i<$ncmd} {incr i} {
   	set cmd($i) [binary format c $fcmd($i)]
  }
# Open port
  set fh $config(port)
  set ninp 0
  set ks 27
# Send request
  for {set i 0} {$i<$ncmd} {incr i} {
    puts -nonewline $fh $cmd($i)
  }
  flush $fh
# Get respond
  while {1} {
    set ddd [read $fh 1]
    binary scan $ddd c bt
#puts "btB $bt"
#update
    if {$bt==27} break
  }

  set ddd [read $fh 1]
  binary scan $ddd c ninp
  set ks [expr {$ks+$ninp}]
  set inbuf(0) $ninp

  set ninpd [expr {$ninp+2}]
  for {set i 1} {$i<$ninpd} {incr i} {
    set ddd [read $fh 1]
    binary scan $ddd c num
#puts "num$i $num"
#update
    set inbuf($i) [expr {( $num + 0x100 ) % 0x100}]
    set ks [expr {$ks+$inbuf($i)}]
  }

  set ks [expr {$ks&255}]
  return $ks
}

# Загрузка задания на измерения
proc loadTask { ltask } {
global config inbuf

# Begin
  stopDev

  set offset 0
  set blen 32
  if {$ltask < 32} { set blen $ltask }
#puts "ozuwrbeg"
#update
  set ks [bzapros ozuwrbeg 33 $blen $offset]
  if {$ks != 13} { return -1}
#NS номер сообщения. 128 - "Диагностика" Номер ошибки, параметры
  if {$inbuf(1) != 128} { puts "<$inbuf(1)><$inbuf(2)><$inbuf(3)><$inbuf(4)>"; return -2 }
  if {$inbuf(2) != 0} { return -3 }
#puts "<$inbuf(1)><$inbuf(2)><$inbuf(3)><$inbuf(4)>";
#update
  # Next
  set offset [expr {$offset + $blen}]
  set ltask [expr {$ltask - $blen}]
  if {$ltask < 32} { set blen $ltask }

  while { $ltask > 0 } {
#puts "ozuwrnxt"
#update
   set ks [bzapros ozuwrnxt 33 $blen $offset]
   if {$ks != 13} { return -4}
   if {$inbuf(1) != 128} { return -5 }
   if {$inbuf(2) != 0} { return -6 }
#puts "<$inbuf(1)><$inbuf(2)><$inbuf(3)><$inbuf(4)>";

   set offset [expr {$offset + $blen}]
   set ltask [expr {$ltask - $blen}]
   if {$ltask < 32} { set blen $ltask }
  }

  # End
#puts "ozuwrend"
#update
  set ks [azapros ozuwrend 1]
  if {$ks != 13} { return -7}
  if {$inbuf(1) != 128} { return -8 }
  if {$inbuf(2) != 0} { return -9 }
#puts "<$inbuf(1)><$inbuf(2)><$inbuf(3)><$inbuf(4)>";

#puts "Task loaded successfully !"
#update
  return 1
}

# Запуск УСО
proc runDev {} {
global config inbuf

  set ks [azapros run 1]
  if {$ks != 13} { return -10}
#NS номер сообщения. 129 - "Текущий режим работы"
  if {$inbuf(1) != 129} { return -11 }
#RR режим измерения 1
  if {$inbuf(2) != 1}  { puts "<$inbuf(1)><$inbuf(2)>"; return -12 }

  return 1
}

# Останов УСО
proc stopDev {} {
global config inbuf

  set ks [azapros stop 1]
  if {$ks != 13} { return -13}
#NS номер сообщения. 129 - "Текущий режим работы"
  if {$inbuf(1) != 129} { return -14 }
#RR режим останова 0
  if {$inbuf(2) != 0}  { puts "<$inbuf(1)><$inbuf(2)>"; return -15 }

  return 1
}

# Запрос измеренных данных
proc getData { npar regim } {
global command config inbuf value

# Send request
  set fcmd(0) 27
  set ncmd 2

  foreach {b} $command(getpar) {
  	set fcmd($ncmd) $b
  	incr ncmd
  }

  set fcmd(1) [expr {($ncmd-2)&255}]

# контрольная сумма
  set ksinp 0
  for {set i 0} {$i<$ncmd} {incr i} {
   set ksinp [expr {$ksinp+$fcmd($i)}]
  }
  set ksinp [expr {13 - ($ksinp&255)}]
  set fcmd($ncmd) $ksinp
  incr ncmd

# convert to binary
  for {set i 0} {$i<$ncmd} {incr i} {
  	set cmd($i) [binary format c $fcmd($i)]
  }

# Open port

  set fh $config(port)

  for {set i 0} {$i<$ncmd} {incr i} {
    puts -nonewline $fh $cmd($i)
  }
	flush $fh
#puts "send"
#update
# Get respond for all parameters
  for {set j 0} {$j<$npar} {incr j} {

    while {1} {
      set ddd [read $fh 1]
      binary scan $ddd c bt
      if {$bt==27} break
    }

    set ks 27

# общее число байт,номер сообщения,номер параметра
    for {set i 0} {$i<3} {incr i} {
      set inbuf($i) [read $fh 1]
      binary scan $inbuf($i) c num
# puts "$j) $i $num"
      set inbuf($i) [expr {( $num + 0x100 ) % 0x100}]
      set ks [expr {$ks+$inbuf($i)}]
    }

# Читаем измеренное значения
    set value($j) [read $fh 4]

# Читаем контрольную сумму
    set bksi [read $fh 1]
    binary scan $bksi c num
    set ksi [expr {( $num + 0x100 ) % 0x100}]

# Переводим из бинарной формы в ASCII, вычисляем контрольную сумму
    binary scan $value($j) cccc x1 x2 x3 x4
    set ks [expr {$ks + $x1 + $x2 + $x3 + $x4}]
    binary scan $value($j) f y
    set value($j) $y
#puts "value($j)=$value($j)"
#update
    set ks [expr {$ks + $ksi}]

    set ks [expr {$ks&255}]

    if {$ks != 13} { puts "ks=$ks"; return -16}
#NS номер сообщения. 132 - "Значение параметра"
    if {$inbuf(1) != 132} { puts "<$inbuf(1)><$inbuf(2)>"; return -17 }
  }
  return 1
}
