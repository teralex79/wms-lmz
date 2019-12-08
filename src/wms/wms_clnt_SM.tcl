proc SmContr {} {
global wms

 if {$wms(sm)} {
   runsm
 } else {
   exitsm
 }
}

proc runsm {} {
global wms

# start sm
  exec -- wish WMS_SM_MOXA.tcl &
  set x 0
  after 500 {set x 1}
  vwait x

# establish communication with sm program
  if {[catch {set s [socket localhost 4441]}]} {

     tk_messageBox -message "Error localhost SM 4441" -title "Error localhost" -type ok -icon error
  } else {

    fconfigure $s -buffering line
    fileevent $s readable [list handleSMInput $s]

# command to init Step Motors
    set wms(socket,sm) $s

    foreach name $wms(zond) {

      puts $wms(socket,sm) "AddZond [string range $name 1 end] [list $wms($name,cntr,smc_tr) $wms($name,ch,smc_tr)] [list $wms($name,cntr,smc_ang) $wms($name,ch,smc_ang)]"
    }

    vwait wms(socket,sm,1)
    set wms(zondinit) 0
  }
}

# Прием командного отклика от SM сервера
proc handleSMInput {f} {
global wms

# Delete the handler if the input was exhausted.
  if {[eof $f]} {
    fileevent $f readable {}
    close     $f
    .menu.init entryconfigure 2 -state disabled

    set wms(sm,tr,init) 0
    set wms(sm,ang,init) 0

    if {$wms(sph)} {Speech "Коонтроолер Шааговых моторов -  отключен!" }
    return
  }

# Read and handle the incoming information.
  set r [gets $f]
  set lr [eval list $r]
  if {[llength $lr]} {

    for {set i 0} {$i<6} {incr i} {

      set idata($i) [lindex $lr $i]
    }
    set wms(socket,sm,1) "$idata(1) $idata(2)"

    switch -exact $idata(1) {

      "Move" {

        switch $idata(2) {

          "done" {

            foreach name $wms(zond) {
              set flag($name) 0
              if {$wms($name,ch,smc_tr)==$idata(4) && $wms($name,cntr,smc_tr)==$idata(3)} {
                set wms($name,tr,current) [format "%6.2f" [expr {$idata(5) - $wms($name,tr_off)}]]
                set wms($name,move,tr)  0
                set flag($name) 1
                update
              } elseif {$wms($name,ch,smc_ang)==$idata(4) && $wms($name,cntr,smc_ang)==$idata(3)} {
                set wms($name,ang,current) [format "%6.2f" [expr {$idata(5) - $wms($name,ang_off)}]]
                set wms($name,move,ang) 0
                set flag($name) 1
                update
              }

              if {$flag($name) && !$wms($name,move,tr) && !$wms($name,move,ang)} {

                MeasFullWet $name 1 1
              }
            }
          }

          "run" {

            foreach name $wms(zond) {
              if {$wms($name,ch,smc_tr)==$idata(4)} {

                set wms($name,tr,current) [format "%6.2f" [expr {$idata(5) - $wms($name,tr_off)}]]
                update
              } elseif {$wms($name,ch,smc_ang)==$idata(4)} {

                set wms($name,ang,current) [format "%6.2f" [expr {$idata(5) - $wms($name,ang_off)}]]
                update
              }
            }
          }

          "start" {

            set wms(stat) "Zonds Move"
          }
        }
      }

      "Init" {

        switch $idata(2) {

          "done" {
            foreach name $wms(zond) {
              if {$wms($name,ch,smc_tr)==$idata(4)} {

                set wms($name,tr,current) 0.00
              } elseif {$wms($name,ch,smc_ang)==$idata(4)} {

                set wms($name,ang,current) 0.00
              }
            }
          }

          "finish" {

            set wms(stat) "Zonds Inited"
            set wms(zond,init) 1
          }

          "start" {

            set wms(stat) "Zonds Init"
          }
        }
      }

      "Where" {

        foreach name $wms(zond) {
          if {$wms($name,ch,smc_tr)==$idata(3)} {

            set wms($name,tr,current) [format "%6.2f" [expr {$idata(4) - $wms($name,tr_off)}]]
          } elseif {$wms($name,ch,smc_ang)==$idata(3)} {

            set wms($name,ang,current) [format "%6.2f" [expr {$idata(4) - $wms($name,ang_off)}]]
          }
        }
      }
      
      "Stop" {

        set wms(zond,stop) 1
        set wms(pause) 1
      }

      "Error" {

        set wms(zond,fail) 1
        set wms(pause) 1
        tk_messageBox -message $lr -title "Error SM" -type ok -icon error
      }
    }
  }
}

proc execCmdSM {cmd arg1 arg2 arg3} {
global wms

  puts $wms(socket,sm) "$cmd $arg1 $arg2 $arg3"
  flush $wms(socket,sm)
}

proc InitZond {par par2} {
global wms

  set wms(zond,init) 0

  if {$par=="tr" || $par=="ang"} {

    execCmdSM Init all $par 0
    if {!$wms(zond,init)} {
      vwait wms(zond,init)
    }
  } elseif {$par=="both"} {

    InitZond ang 0
    after 100

    if {!$wms(zond,fail) && !$wms(zond,stop)} {

      InitZond tr 0
    }
  } else {

    execCmdSM Init chan $par $par2
    if {!$wms(zond,init)} {
    
      vwait wms(zond,init)
    }
  }
}

proc exitsm {} {
global wms

  puts $wms(socket,sm) "Exit"
  flush $wms(socket,sm)
  close $wms(socket,sm)

  set wms(sm,tr,init) 0
  set wms(sm,ang,init) 0

  set wms(socket,sm,1) off
}
