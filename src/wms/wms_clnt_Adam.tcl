## ���������� � �������� ���������/����������� ����� � ������� ADAM ��� SWMS

proc RunAdam {name} {
global rs wms
 if {$wms(active)} {
  if {$wms($name,active)} {
    set a [lsearch $wms(port) "$wms($name,adr,moxa):$wms($name,port,adam)"]
    if {$a==-1} {
      if {[catch {socket $wms($name,adr,moxa) $wms($name,port,adam)} rs($name,adam)]} {

         set answ [tk_messageBox -message "��� ����� � $wms($name,adr,moxa):$wms($name,port,adam) ������. ��������� ����������� ���������." -title "Error" -type ok -icon error]
      } else {
         fconfigure $rs($name,adam) -buffering line -translation cr -blocking 0
         fileevent  $rs($name,adam) readable [list handleRemCmdAdam $rs($name,adam) $name]
         lappend wms(port) "$wms($name,adr,moxa):$wms($name,port,adam)"
         lappend wms(portname) "$name"
      }
    }
    if {$wms(zndjntctr)} {ZondContrAdam 0 $name}
  } else {

    set a [lsearch $wms(port) "$wms($name,adr,moxa):$wms($name,port,adam)"]
    if {$a!=-1} {
      set flag 1
      foreach nm $wms(zond) {
        if {$wms($nm,active) && "$wms($name,adr,moxa):$wms($name,port,adam)"=="$wms($nm,adr,moxa):$wms($nm,port,adam)"} {set flag 0}
      }
      if {$flag} {
        catch {close $rs([lindex $wms(portname) $a],adam)}
        set wms(port) [lreplace $wms(port) $a $a]
        set wms(portname) [lreplace $wms(portname) $a $a]
      }
    }
  }
 } else {
   catch {close $rs($name,adam)}
   set a [lsearch $wms(port) "$wms($name,adr,moxa):$wms($name,port,adam)"]
   set wms(port) [lreplace $wms(port) $a $a]
 }
}

proc handleRemCmdAdam {f name} {
global wms ent

# Delete the handler if the input was exhausted.
  if {[eof $f]} {
      fileevent $f readable {}
      close     $f
      return
  }

  set ent(11) [gets $f]
  set wms(adam,ready) 1
}

proc ZondContrAdam {i name} {
global ent rs wms
  if {$wms(zndjntctr)} {
    if {!$i || [expr {($i==1 && $wms($name,Io1)&& (($wms($name,new_meth) && $wms($name,tr,current)<$wms($name,coord_in_tube) ) || !$wms($name,new_meth))) || ($i==2 && $wms($name,Io2)&& (($wms($name,new_meth) && $wms($name,tr,current)<$wms($name,coord_in_tube) ) || !$wms($name,new_meth)))}]} {

      set wms($name,nomove,tr) 0
      set adr [format "%02X" $wms($name,adr,adam)]
      if {$i} {

        set wms(adam,ready) 0
        SendCommandAdam $name act "\@${adr}DO00"
        if {!$wms(adam,ready)} {vwait wms(adam,ready)}
      } else {

        set wms(adam,ready) 0
        SendCommandAdam $name act "\@${adr}DO01"
        if {!$wms(adam,ready)} {vwait wms(adam,ready)}
      }

      after 1000
      CheckZond $name $adr 1
    } else {

       set wms($name,done) 1
    }
  } else {
    set wms($name,done) 1
  }
}

proc CheckZond {name adr rep} {
global rs wms val ent
  set wms(adam,ready) 0
  SendCommandAdam $name check "\@${adr}DI"
  if {!$wms(adam,ready)} {vwait wms(adam,ready)}
  set pos [string range $ent(11) end-2 end-2]

  if {[string length $pos]==0} {

    tk_messageBox -message "������ ��������/����������." -title "Error" -type ok -icon error
    set pos 1
  }
  if {!$pos} {

    set a "��������"
    set b "�� ������"
    set c "������"
  } else {

    set a "������"
    set b "�� ��������"
    set c "��������"
  }
  if {[string range $ent(11) end end]} {

    set wms($name,state,current) $c
    set wms($name,done) 1
    update
  } else {
    if {$rep<3} {

      after [expr {($rep + 1)*1500}]
      incr rep
      after 100
      CheckZond $name ${adr} $rep
    } else {
      set answ [tk_messageBox -message "���� $name $b. ��������� �������?" -title "Error" -type yesno -icon error]
      if {$answ=="yes"} {
        CheckZond $name ${adr} 1
      } else {

        set wms($name,done) 1
      }
    }
  }
}

proc SendCommandAdam {name act cmd} {
global rs wms ent

  if {$wms(active)} {
    puts $rs($name,adam) $cmd
    flush $rs($name,adam)
  } else {
    if {$act == "check"} {
      if {$wms($name,state,next) == "������"} {
        set ent(11) "001"
      } else {
        set ent(11) "101"
      }
    }
    after 100 "set wms(adam,ready) 1"
  }
}

