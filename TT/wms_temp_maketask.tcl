proc ins_2b2pos { vint ind } {
global task

 set bx [binary format s $vint] 
 binary scan $bx cc x1 x2
 set x1 [binary format c [expr {( $x1 + 0x100 ) % 0x100}]]
 set x2 [binary format c $x2]

 set task($ind) $x1; incr ind
 set task($ind) $x2;

}

proc makeTask {} {
global config par sens ib task tt

  catch { unset task }

  set ib 0
  set b0 [binary format c $ib]

  set num_par [llength $config(pars_name)]
  set scm {}
  for {set i 0} {$i<$num_par} {incr i} {
  	lappend scm $i
  }

# Блок:заголовок: A5h(165),01h,Число градуировок - 2 байта
  #set task($ib) [binary format c 165]

# Блок описания параметров
# Номер блока=3
  set task($ib) [binary format c 3]
  incr ib
  # Два байта под длину блока
  set task($ib) [binary format c 0]
  incr ib
  set task($ib) [binary format c 0]
  incr ib

# Число параметров - 1 байт
  set task($ib) [binary format c $num_par]
  incr ib

  set p 1
  foreach {i} $scm {

# Номер ИП(1-60)	1 байт
puts -nonewline "$p:"
    set task($ib) [binary format c $p]
    incr ib
    incr p
# Номер канала(1-30)	1 байт
puts -nonewline "$par($i,can):"
    set task($ib) [binary format c $par($i,can)]
    incr ib
# Тип датчика		1 байт
puts -nonewline "$par($i,td):"
    set task($ib) [binary format c $par($i,td)]
    incr ib
# Номер ПХС		1 байт
puts -nonewline "$par($i,xc):"
    set task($ib) [binary format c $par($i,xc)]
    incr ib
# Гр.пользователя (0-30)	1 байт
    set task($ib) $b0
    incr ib
# Гр.стандартная  (0-3)	1 байт
#puts "$par($i,tg):"
    set task($ib) [binary format c $par($i,tg)]
    incr ib
  }

# Длина блока=число байт в блоке без первых трех байтов заголовка
  set lbl [expr {$ib-3}]
  ins_2b2pos $lbl 1

# Блок завершения A5H
  set task($ib) [binary format c 165]
  incr ib

# Контр.сумма
  set lks 0
  for {set i 0} {$i<$ib} {incr i} {
    set x 0
    scan $task($i) %c x
    set lks [expr {$lks + $x}]
  }

  set bx [binary format i $lks]
  binary scan $bx cccc x1 x2 x3 x4
  set x1 [binary format c [expr {( $x1 + 0x100 ) % 0x100}]]
  set x2 [binary format c [expr {( $x2 + 0x100 ) % 0x100}]]
  set x3 [binary format c [expr {( $x3 + 0x100 ) % 0x100}]]
  set x4 [binary format c $x4]
  set task($ib) $x1; incr ib
  set task($ib) $x2; incr ib
  set task($ib) $x3; incr ib
  set task($ib) $x4; incr ib

# Контрольная запись в файл
  set fd [open "$tt(path)/TT/tasktcl.dat" "w+"]
  fconfigure $fd -translation binary
  for {set i 0} {$i<$ib} {incr i} {
    puts -nonewline $fd $task($i)
  }
  close $fd
  return $ib
}
