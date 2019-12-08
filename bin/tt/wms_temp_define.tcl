## Trim left zeros from the string
proc rml0 { str } {

  while { [string first "0" $str]==0 } {
    set str [string range $str 1 end]
    if { [string length $str]==1 } break
  }
  return $str
}

## Gorner function
proc gorner { x a0 a1 a2 a3 } {

  return [expr {$a0+$x*($a1+$x*($a2+$x*$a3))}]
}

## Read canals.def
proc define { fdef } {
global par sens config

  set fh [open $fdef r]
  set f 0
  set ia 0
  set is 0
  set config(pars) {}
  set config(pars_name) {}

  set data [read $fh]
  close $fh
  set lines [split $data \n]

  set i 0
  foreach line $lines {
    if { ![string match "#*" $line] } {
      if { $f>0 && [string match {\[*} $line] } { set f 0 }
# # # parameters
      if { $f==1 } {
        set v [eval list $line]
        set t [lindex $v 1]
        set name [lindex $v 0]

        lappend config(pars_name) $name

        set par($ia,name) $name
        set par($ia,num) [rml0 [lindex $v 1]]
        set par($ia,can) [rml0 [lindex $v 2]]
        set par($ia,td) [lindex $v 3]
        set par($ia,tg) [lindex $v 4]
        set par($ia,xc) [rml0 [lindex $v 5]]
        set par($ia,ugr) [rml0 [lindex $v 6]]
        set par($ia,fp) [lindex $v 7]
        set par($ia,sens) [lindex $v 8]

        incr ia
      }
# # # sensors
      if { $f==2 } {
        set v [eval list $line]
        set sn [lindex $v 1]
        set sens($sn,a0) [lindex $v 2]
        set sens($sn,a1) [lindex $v 3]
        set sens($sn,a2) [lindex $v 4]
        set sens($sn,a3) [lindex $v 5]
      }

      if { [string match {\[parameters\]} $line] } { set f 1 }
      if { [string match {\[sensors\]} $line] } { set f 2 }
    }
  }
  set config(n_par) $ia
}

