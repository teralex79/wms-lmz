proc TTContr {} {
global wms

 if {$wms(temp)} {
   runtt $wms(adr_tt)
#   runtt localhost
 } else {
#   exittt
   catch {close $wms(socket,tt)}
 }
}

set wms(runtt) 0

proc runtt {adr} {
global wms

# establish communication with sm program
  set flag 0
  set lst {}
  foreach adr_item [concat $adr $wms(tt_adr_list)] {
    if {[lsearch $lst $adr_item]==-1} {
      lappend lst $adr_item
      set wms(Info) "Connecting to TT $adr_item"
      update
      if {![catch {set s [socket $adr_item 4442]}]} {
        set flag 1
        set wms(Info) "Connected TT to $adr_item"
        update
        break
      }
    }
  }

  if {$flag} {
    set wms(socket,tt) $s
    fconfigure $s -buffering line
    fileevent $s readable [list handleSocketTT $s]
    SendSocketTT ConTT 0 0 0 0
    after 1000 FormInfo
  } else {
    set answ [tk_messageBox -message "Error $adr TT 4442\n Запустить TruTemp?" -title "Error $adr" -type yesno -icon error]
    if {$answ=="yes"} {
      exec -- wish "./WMS_TT.tcl" &
      after 200 "runtt localhost"
    } else {
      set wms(temp) 0
      SaveProp
      after 1000 FormInfo
    }
  }
}

# Прием командного отклика от TrueTemp сервера
proc handleSocketTT {f} {
global wms

# Delete the handler if the input was exhausted.
  if {[eof $f]} {

    fileevent $f readable {}
    close     $f
    set wms(temp) 0

    if {$wms(sph)} {Speech "Трю Темп -  отключен!" }
    SaveProp; TTContr
    FormInfo
    return
  }

# Read and handle the incoming information.
  set r [gets $f]
  set lr [eval list $r]
  if {[llength $lr]} {

    for {set i 0} {$i<10} {incr i} {

      set idata($i) [lindex $lr $i]
    }

    switch $idata(1) {

      "Meas" {

        switch $idata(2) {

          "done" {

            if {$idata(5) < 999} {
              set wms($idata(3),temp,$idata(4)) [format "%6.2f" $idata(5)]
              if {$idata(6)>=$wms(tempaver)} {
            
                set wms(busytemp) 0
                set wms($idata(3),busytemp) 0
              }
            } else {
              MeasTemp $idata(3) $idata(4) $wms($idata(3),repeat) $wms(tempaver)
            }
          }
        }
      }

      "Error" {

        tk_messageBox -message $lr -title "Error TT" -type ok -icon error
      }
    }
  }
}

proc MeasTemp {name n rep aver} {
global wms
#puts "Meas Temp $name $n $rep $aver"
  SendSocketTT Meas $name $n $rep $aver
}

proc SendSocketTT {cmd arg1 arg2 arg3  arg4} {
global wms
  catch {
    puts $wms(socket,tt) "$cmd $arg1 $arg2 $arg3 $arg4"
    flush $wms(socket,tt)
  }
}

proc exittt {} {
global wms

  puts $wms(socket,tt) "Exit"
  flush $wms(socket,tt)
  close $wms(socket,tt)

  set wms(socket,tt,1) off
}
