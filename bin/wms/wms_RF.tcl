proc ReadIni {} {
global wms meas

  if {![catch {set ini [open "$wms(DATAPATH)/Config/[info hostname]_prop.ini" "r"]}]} {

    set data [read $ini]
    close $ini

    set lines [split $data \n]

    set i 0
    foreach str $lines {
      if {[string length $str]>0 && [string first # $str]!=0 && [lindex $str 0]!="#"} {
        set [lindex $str 0] [lindex $str 1]
      }
      incr i
    }
  }
  FormInfo
}

proc ReadCoef {name} {
global wms

  if {![catch {set of [open "./Data/Config/$name/Coef_$wms($name,type)_$name.DAT" "r"]}]} {
    set data [read $of]
    close $of

    set lines [split $data \n]

    set colour [lindex $lines 0]
    set coef   [lindex $lines 1]

    foreach clr $colour cf $coef {
      set wms($name,coef,$clr) $cf
    }
  } else {
    foreach lamda $wms($name,swms,lamda) {
      set wms($name,coef,$lamda) 1.0000
    }
  }
}

proc ReadRWV {name} {
global wms lststr

  set name1 [string range $name 1 end]

  set of [open "./Data/Config/$name/RWV_${name1}.DAT"]
  set data [read $of]
  close $of

  set lines [split $data \n]
  set lststr($name1,rwv) $lines

  set wms($name,tr) {}
  set wms($name,ang) {}
  set wms($name,dens_l) {}

  set i 1
  foreach str $lines {
    set str [eval list $str]

    if {[string length $str]>0} {

      lappend wms($name,tr) [lindex $str 0]
      lappend wms($name,ang) [lindex $str 1]
      lappend wms($name,dens_l) [lindex $str 2]

      if {[llength [lindex $str 3]]>0} {

        set wms($name,wet,$i) [lindex $str 3]
      } else {

        set wms($name,wet,$i) 1
      }
      incr i
    }
  }

  set wms($name,points) [expr {$i - $wms($name,firstpoint)}]

  set wms($name,tr,current) 0
  set wms($name,tr,next) [lindex $wms($name,tr) 0]

  set wms($name,ang,current) 0
  set wms($name,ang,next) [lindex $wms($name,ang) 0]
}
