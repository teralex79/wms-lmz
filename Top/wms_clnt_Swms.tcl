proc string2hex {s} {
  binary scan $s H* hex
  regsub -all (..) $hex {\\x\1}
  return $hex
}

proc handleRemCmdSpec {f name} {
global wms

# Delete the handler if the input was exhausted.
  if {[eof $f]} {
      fileevent $f readable {}
      close     $f
      return
  }
# Read and handle the incoming information.
  set a [catch {set bs0 [read $f]}]

  if {!$a} {
    set lngth "[string length $bs0]"
    if {$lngth>0} {

      for {set i 0} {$i<$lngth} {incr i} {
        set bs_bit [string range $bs0 $i $i]
        if {![string is alnum $bs_bit]} {
          binary scan $bs_bit a1 bs_bin

          set bs_hex [string2hex $bs_bin]
          switch [string tolower $bs_hex] {

            "00"       {set bs1 #NUL}
            "01"       {set bs1 #SOH}
            "02"       {set bs1 #STX}
            "03"       {set bs1 #ETX}
            "04"       {set bs1 #EOT}
            "05"       {set bs1 #ENQ}
            "06"       {set bs1 #ACK}
            "07"       {set bs1 #BEL}
            "08"       {set bs1 #BS }
            "09"       {set bs1 #TAB}
            "0a"       {set bs1 #LF }
            "0b"       {set bs1 #VT }
            "0c"       {set bs1 #FF }
            "0d"       {set bs1 #CR }
            "0e"       {set bs1 #SO }
            "0f"       {set bs1 #SI }
            "10"       {set bs1 #DLE}
            "11"       {set bs1 #DC1}
            "12"       {set bs1 #DC2}
            "13"       {set bs1 #DC3}
            "14"       {set bs1 #DC4}
            "15"       {set bs1 #NAK}
            "16"       {set bs1 #SYN}
            "17"       {set bs1 #ETB}
            "18"       {set bs1 #CAN}
            "19"       {set bs1 #EM }
            "1a"       {set bs1 #SUB}
            "1b"       {set bs1 #ESC}
            "1c"       {set bs1 #FS }
            "1d"       {set bs1 #GS }
            "1e"       {set bs1 #RS }
            "1f"       {set bs1 #US }
            "default"  {set bs1 $bs_bin}
          }
        } else {

          set bs1 $bs_bit
        }
        set wms($name,string) "$wms($name,string)$bs1"
      }

      set wms($name,answ) [eval list [string map {#ACK " " #CR " " #LF " "} $wms($name,string)]]
      if {([string match -nocase "*>*" $wms($name,string)] && $wms($name,cmd)!="S") || ($wms($name,cmd)=="S" && [llength [lsearch -all $wms($name,answ) "*>*"]]==2)} {
        set wms($name,socket,status) 0
      }
    }
  }
}

proc Meas_SWMS {name join n} {
global wms

  if {$wms(active)} {
    SendCmdCOM meas aA $name
    SendCmdCOM meas I$wms($name,swms,IntTime) $name
    SendCmdCOM meas P$wms($name,swms,PixMode) $name
    SendCmdCOM meas S $name
    set wms($name,swms,Imeas,$n,$join) [lreplace [lreplace $wms($name,answ) 0 7] end-1 end]

  } else {
    set wms($name,swms,Imeas,$n,$join) {}
    set sigma 120000.
    set pi 3.14
    set cnt 0
    foreach lamda $wms($name,swms,lamda) {
      set dev 0.2
      set mid 1.0
      set rnd [expr {$mid + ($dev/2 - rand()*$dev)}]

      if {$cnt < 4 || $cnt > 1037} {
        set val 0.1
      } else {
        set val [expr {(1 + $join)*pow(10,9)*$rnd*exp(0 - pow(($lamda-600000.)/$sigma,2)/2.)/($sigma*pow(2*$pi,0.5))}]
      }
      lappend wms($name,swms,Imeas,$n,$join) $val
      incr cnt
    }
  }

  set Iblack ""
  foreach item {0 1 2 3 1038 1039 1040 1041 1042 1043} {
    lappend Iblack [lindex $wms($name,swms,Imeas,$n,$join) $item]
  }

  set wms($name,swms,Iblack) [lindex [lsort -increasing $Iblack] 5]
  set wms($name,swms,Icalc,$n,$join) ""

  foreach item $wms($name,swms,Imeas,$n,$join) {
    lappend wms($name,swms,Icalc,$n,$join) [expr {$item - $wms($name,swms,Iblack)}]
  }

  if {!$wms($name,Io1) || !$wms($name,Io2)} {
    if {$wms($name,tr,current)<10 && $n==1 && $join==0} {
      foreach item $wms($name,swms,Icalc,$n,$join) lamda $wms($name,swms,lamda) {
        set wms($name,$lamda,Io) $item
      }
    }
  }
  if {$join} {
    if {$n!="k"} {
#      if {!$wms($name,new_meth) || ($wms($name,tr,current)<10 && $n==1)} {
        foreach item $wms($name,swms,Icalc,$n,$join) lamda $wms($name,swms,lamda) {
          set wms($name,$lamda,Io) [expr {$item*$wms($name,coef,$lamda)}]
        }
#      }
    }
    switch $join {
      "1" {
        set wms($name,Io1,Spectrum) "measured"
        if {$n=="k" || !$wms($name,Io2)} {set wms($name,Io2,Spectrum) "measured"}
      }
      "2" {
        set wms($name,Io2,Spectrum) "measured"
        if {!$wms($name,Io1)} {set wms($name,Io1,Spectrum) "measured"}
      }
    }
  } else {set wms($name,I,Spectrum) "measured"}

  if {$n!="k"} {
    if {!$join} {
      catch {global x${name}I x${name}IIo}
      set x${name}I(++end)   $wms($name,tr,current)
      set x${name}IIo(++end) $wms($name,tr,current)

      set wms($name,tr2)     $wms($name,tr,current)
      foreach i {1 2 3 4} l1 {300 460 520 630} n1 {127 331 408 550} {
        catch {global y${name}$l1 y${name}IIo$l1}
        set lmd($i) [lindex $wms($name,swms,lamda) $n1]
        set Io($i) $wms($name,$lmd($i),Io)
        if {$Io($i)==0} {set Io($i) 1}
        set Icalc($i) [lindex $wms($name,swms,Icalc,$n,$join) $n1]
        set y${name}${l1}(++end) $Icalc($i)
        set y${name}IIo${l1}(++end) [expr {1.0*$Icalc($i)/$Io($i)}]
        set wms($name,IIo,$l1) [format "%4.2f" [expr {1.0*$Icalc($i)/$Io($i)}]]
        set wms($name,I,$l1) [format "%6.0f" $Icalc($i)]
      }
    }
  }

  catch {global x${name}Spec y${name}Spec}
  x${name}Spec set {}
  y${name}Spec set {}

  for {set i 15} {$i<1029} {incr i} {

    set x${name}Spec(++end) [lindex $wms($name,swms,lamda) $i]
    set y${name}Spec(++end) [lindex $wms($name,swms,Icalc,$n,$join) $i]
  }
  set wms(ready) 1
  incr wms($name,cont)
}

proc runSWMS {name} {
global wms

# establish communication with swms program
  if {$wms(active)} {
    if {$wms($name,active)} {
      set a [lsearch $wms(port) "$wms($name,adr,moxa):$wms($name,port,swms)"]
      if {$a==-1} {
        if {[catch {socket $wms($name,adr,moxa) $wms($name,port,swms)} wms($name,socket,swms)]} {

           set answ [tk_messageBox -message "Нет связи с $wms($name,adr,moxa):$wms($name,port,swms) портом. Проверьте подключение устройств." -title "Error" -type ok -icon error]
        } else {
          fconfigure $wms($name,socket,swms) -buffering line -translation cr -blocking 0
          fileevent  $wms($name,socket,swms) readable [list handleRemCmdSpec $wms($name,socket,swms) $name]

          lappend wms(port) "$wms($name,adr,moxa):$wms($name,port,swms)"
          lappend wms(portname) "$name"

          Init_SWMS $name
        }
      } else {

        set wms($name,socket,swms) $wms([lindex $wms(portname) $a],socket,swms)
        Init_SWMS $name
      }
    } else {

      set a [lsearch $wms(port) "$wms($name,adr,moxa):$wms($name,port,swms)"]
      if {$a!=-1} {
        set flag 1
        foreach nm $wms(zond) {
          if {$wms($nm,active) && "$wms($name,adr,moxa):$wms($name,port,swms)"=="$wms($nm,adr,moxa):$wms($nm,port,swms)"} {set flag 0}
        }
        if {$flag} {
          catch {close $wms([lindex $wms(portname) $a],socket,swms)}
          set wms(port) [lreplace $wms(port) $a $a]
          set wms(portname) [lreplace $wms(portname) $a $a]
        }
      }
    }
  } else {
    set lmd1 200000
    foreach item {SName l0 l1 l2 l3 slc nlcc0 nlcc1 nlcc2 nlcc3 nlcc4 nlcc5 nlcc6 nlcc7 pnlc} {
      set wms($name,swms,$item) "no_act"
      incr cnt
    }
    set wms($name,swms,lamda) ""
    for {set i 0} {$i<1044} {incr i} {
      lappend wms($name,swms,lamda) $lmd1
      incr lmd1 766
    }
  }
}

proc SendCmdCOM {a cmd name} {
global wms

  set wms($name,socket,status) 1
  set wms($name,string) ""
  set wms($name,cmd) $cmd
  if {$cmd=="aA" || $cmd=="bB" || $cmd=="v"} {
    puts -nonewline $wms($name,socket,swms) $cmd
  } else {
    puts $wms($name,socket,swms) $cmd
  }
  flush $wms($name,socket,swms)
  if {$wms($name,socket,status)} {vwait wms($name,socket,status)}
}

proc Init_SWMS {name} {
global wms

  if {$name=="all"} {
    foreach name $wms(zond) {
      if {$wms($name,type)=="swms"} {
        Init_SWMS $name
      }
    }
  } else {

    SendCmdCOM init aA $name

    SendCmdCOM init "?x-1" $name
    if {[lindex $wms($name,answ) 0]=="?x-1"} {
      set cnt 1
      foreach item {SName l0 l1 l2 l3 slc nlcc0 nlcc1 nlcc2 nlcc3 nlcc4 nlcc5 nlcc6 nlcc7 pnlc} {
        set wms($name,swms,$item) [lindex $wms($name,answ) $cnt]
        incr cnt
      }
      set wms($name,swms,lamda) ""
      for {set i 0} {$i<1044} {incr i} {

        set lmd1 [expr {round(1000*($wms($name,swms,l0) + $wms($name,swms,l1)*$i + $wms($name,swms,l2)*$i*$i + $wms($name,swms,l3)*$i*$i*$i))}]
        lappend wms($name,swms,lamda) $lmd1
      }

      foreach lamda $wms($name,swms,lamda) {

        set wms($name,$lamda,Io) 1
      }

      set wms($name,swms,Init) "inited"
    } else {
      set wms($name,swms,Init) $wms($name,answ)
    }
  }
}

proc EditCoefSWMS {name} {
global wms

  toplevel .edcoef
  wm title .edcoef "Коэффициенты SWMS"
  wm geometry .edcoef "=+50+100"
  wm protocol .edcoef WM_DELETE_WINDOW "destroy .edcoef"

## Таблица коэффициентов SWMS
  set sf [iwidgets::scrolledframe .edcoef.sf -width 800 -height 450]
  grid $sf -row 0 -column 0 -sticky news

  set tb [$sf childsite]

  set rw 0
  set cl1 0
  set cl2 1
  foreach lamda $wms($name,swms,lamda) {
    if {$rw>=40} {
      set rw 0
      incr cl1 2
      incr cl2 2
    }

    label $tb.lb$lamda -text $lamda -relief ridge -width 7
    grid $tb.lb$lamda -row $rw -column $cl1
    entry $tb.en$lamda -textvariable wms($name,coef,$lamda) -width 6
    grid $tb.en$lamda -row $rw -column $cl2
    incr rw
  }

### "Кнопки"

  set bt [frame .edcoef.frbt]
  grid $bt -row 1 -column 0 -sticky news
    set clm 0
    button $bt.save -text "OK" -width 10 -command "SaveCoef $name; destroy .edcoef"
    grid $bt.save -row 0 -column $clm -padx 1 -pady 2
    incr clm
    button $bt.save2 -text "Применить" -width 10 -command "SaveCoef $name; destroy .edcoef; EditCoefSWMS $name"
    grid $bt.save2 -row 0 -column $clm -padx 1 -pady 2
    incr clm
    button $bt.cnsl -text "Отмена" -width 10 -command "ReadCoef $name; destroy .edcoef"
    grid $bt.cnsl -row 0 -column $clm -padx 1 -pady 2
    incr clm
}