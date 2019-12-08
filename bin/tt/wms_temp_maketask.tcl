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

# ����:���������: A5h(165),01h,����� ����������� - 2 �����
  #set task($ib) [binary format c 165]

# ���� �������� ����������
# ����� �����=3
  set task($ib) [binary format c 3]
  incr ib
  # ��� ����� ��� ����� �����
  set task($ib) [binary format c 0]
  incr ib
  set task($ib) [binary format c 0]
  incr ib

# ����� ���������� - 1 ����
  set task($ib) [binary format c $num_par]
  incr ib

  set p 1
  foreach {i} $scm {

# ����� ��(1-60)	1 ����
puts -nonewline "$p:"
    set task($ib) [binary format c $p]
    incr ib
    incr p
# ����� ������(1-30)	1 ����
puts -nonewline "$par($i,can):"
    set task($ib) [binary format c $par($i,can)]
    incr ib
# ��� �������		1 ����
puts -nonewline "$par($i,td):"
    set task($ib) [binary format c $par($i,td)]
    incr ib
# ����� ���		1 ����
puts -nonewline "$par($i,xc):"
    set task($ib) [binary format c $par($i,xc)]
    incr ib
# ��.������������ (0-30)	1 ����
    set task($ib) $b0
    incr ib
# ��.�����������  (0-3)	1 ����
#puts "$par($i,tg):"
    set task($ib) [binary format c $par($i,tg)]
    incr ib
  }

# ����� �����=����� ���� � ����� ��� ������ ���� ������ ���������
  set lbl [expr {$ib-3}]
  ins_2b2pos $lbl 1

# ���� ���������� A5H
  set task($ib) [binary format c 165]
  incr ib

# �����.�����
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

# ����������� ������ � ����
  set fd [open "$tt(path)/TT/tasktcl.dat" "w+"]
  fconfigure $fd -translation binary
  for {set i 0} {$i<$ib} {incr i} {
    puts -nonewline $fd $task($i)
  }
  close $fd
  return $ib
}
